import * as admin from "firebase-admin";

interface Location {
  lat: number;
  lng: number;
}

/**
 * Calculates straight-line Haversine distance in kilometers.
 */
function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export async function getNearestDriver(
  pickupLocation: Location,
  excludedDriverIds: string[],
  restrictVehicles = false
): Promise<string | null> {
  const db = admin.firestore();

  const driversSnapshot = await db.collection("driverProfiles")
    .where("status", "in", ["online", "busy"])
    .get();

  if (driversSnapshot.empty) return null;

  const availableDrivers = driversSnapshot.docs
    .map((doc) => {
      const data = doc.data() as any;
      const lat = data.currentLat ?? data.location?.lat;
      const lng = data.currentLng ?? data.location?.lng;
      return { id: doc.id, ...data, location: { lat, lng } };
    })
    .filter((driver) => {
      const isBasicValid =
        !excludedDriverIds.includes(driver.id) &&
        driver.location?.lat != null &&
        driver.location?.lng != null;
      if (!isBasicValid) return false;

      if (restrictVehicles) {
        const vehicleType = (driver.vehicleType || "").trim().toLowerCase();
        const isAllowedVehicle =
          vehicleType === "motorcycle" ||
          vehicleType === "moto" ||
          vehicleType === "cycle" ||
          vehicleType === "scooter";
        
        return isAllowedVehicle;
      }

      return true;
    });

  if (availableDrivers.length === 0) return null;

  // Calculate Haversine distance for all available drivers to use as standard or fallback metric
  const driversWithMetrics = availableDrivers.map((driver) => {
    const dist = haversineKm(
      pickupLocation.lat,
      pickupLocation.lng,
      driver.location.lat,
      driver.location.lng
    );
    return {
      ...driver,
      haversineDist: dist,
      metric: dist, // default metric is straight-line distance
    };
  });

  const apiKey = process.env.LOCATIONIQ_API_KEY;
  if (apiKey && apiKey !== "mock") {
    const coordinatesStr = [
      `${pickupLocation.lng},${pickupLocation.lat}`,
      ...driversWithMetrics.map((d) => `${d.location.lng},${d.location.lat}`),
    ].join(";");

    try {
      // Use Matrix API to get travel times from pickup to all drivers
      const driverIndices = driversWithMetrics.map((_, i) => i + 1).join(";");
      const url = `https://us1.locationiq.com/v1/matrix/driving/${coordinatesStr}?key=${apiKey}&sources=${driverIndices}&destinations=0`;

      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        for (let i = 0; i < driversWithMetrics.length; i++) {
          const duration = data.durations[i]?.[0];
          if (duration != null) {
            driversWithMetrics[i].metric = duration;
          }
        }
      } else {
        console.warn(`LocationIQ API error: ${response.statusText}. Using Haversine distances.`);
      }
    } catch (error) {
      console.error("Error making LocationIQ request, using Haversine fallback:", error);
    }
  } else {
    console.log("No LOCATIONIQ_API_KEY found or it's 'mock', using Haversine distances.");
  }

  // Sort availableDrivers:
  // 1. Priority to "online" (free) drivers over "busy" drivers.
  // 2. Proximity (duration / distance ascending)
  driversWithMetrics.sort((a, b) => {
    const aFree = a.status === "online" ? 0 : 1;
    const bFree = b.status === "online" ? 0 : 1;
    if (aFree !== bFree) {
      return aFree - bFree; // free drivers first
    }
    return a.metric - b.metric; // nearest first
  });

  return driversWithMetrics[0].id;
}

export async function dispatchNextDriver(orderId: string): Promise<string | null> {
  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    console.warn(`[dispatchNextDriver] Order ${orderId} not found`);
    return null;
  }

  const orderData = orderDoc.data()!;
  const currentStatus = orderData.status;

  // We only dispatch if status is ready or searching
  if (currentStatus !== "ready" && currentStatus !== "searching") {
    console.log(`[dispatchNextDriver] Order ${orderId} status is ${currentStatus}, not ready/searching. Bailing.`);
    return null;
  }

  // If status is ready, it's a new or retry dispatch cycle. Clear any previous attempts so we start fresh.
  if (currentStatus === "ready") {
    console.log(`[dispatchNextDriver] Order ${orderId} status is ready. Cleaning up previous attempts for a fresh dispatch cycle.`);

    // Update order status to searching immediately to reflect in client UI
    await orderRef.update({
      status: "searching",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const prevRequestsSnap = await db.collection("deliveryRequests")
      .where("orderId", "==", orderId)
      .get();

    const prevOrderDriversSnap = await db.collection("orders")
      .doc(orderId)
      .collection("orderDrivers")
      .get();

    if (!prevRequestsSnap.empty || !prevOrderDriversSnap.empty) {
      const cleanupBatch = db.batch();
      prevRequestsSnap.forEach((doc) => cleanupBatch.delete(doc.ref));
      prevOrderDriversSnap.forEach((doc) => cleanupBatch.delete(doc.ref));
      await cleanupBatch.commit();
      console.log(`[dispatchNextDriver] Cleaned up ${prevRequestsSnap.size} requests and ${prevOrderDriversSnap.size} orderDrivers.`);
    }
  }

  // Get previously excluded drivers to avoid sending to them again
  const previousRequests = await db.collection("deliveryRequests")
    .where("orderId", "==", orderId)
    .get();

  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();
  let updatedAnyExpired = false;

  for (const doc of previousRequests.docs) {
    const data = doc.data();
    if (data.status === "pending" && data.expiresAt && data.expiresAt.toDate() < now.toDate()) {
      console.log(`[dispatchNextDriver] Found expired request ${doc.id} during dispatch, expiring it.`);
      batch.update(doc.ref, {
        status: "expired",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      updatedAnyExpired = true;

      // Also update the orderDrivers status to rejected
      const driverId = data.driverId;
      if (driverId) {
        const orderDriverRef = db.collection("orders")
          .doc(orderId)
          .collection("orderDrivers")
          .doc(driverId);
        batch.set(orderDriverRef, {
          status: "rejected",
          rejectionReason: "Request timed out",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }
  }

  if (updatedAnyExpired) {
    await batch.commit();
  }

  // Check if there is already an active pending request for this order to prevent concurrent duplicates
  const activeRequest = previousRequests.docs.find((doc) => {
    const data = doc.data();
    const wasExpiredJustNow = data.status === "pending" && data.expiresAt && data.expiresAt.toDate() < now.toDate();
    return data.status === "pending" && !wasExpiredJustNow;
  });

  if (activeRequest) {
    const activeDriverId = activeRequest.data().driverId;
    console.log(`[dispatchNextDriver] Order ${orderId} already has active pending request ${activeRequest.id} for driver ${activeDriverId}. Bailing.`);
    return activeDriverId;
  }

  const excludedDriverIds = previousRequests.docs.map((doc) => doc.data().driverId);

  const pickupLocation = orderData.vendorLocation || orderData.restaurantLocation || { lat: 0, lng: 0 };
  const vendorId = orderData.vendorId || orderData.restaurantId || "";
  let restrictVehicles = true; // Default to true (treat legacy/unspecified as restaurant)

  if (vendorId) {
    const vendorDoc = await db.collection("vendors").doc(vendorId).get();
    if (vendorDoc.exists) {
      if (pickupLocation.lat === 0 && pickupLocation.lng === 0) {
        pickupLocation.lat = vendorDoc.data()?.latitude || 0;
        pickupLocation.lng = vendorDoc.data()?.longitude || 0;
      }
      const vendorType = (vendorDoc.data()?.vendorType || "").trim().toLowerCase();
      if (vendorType && vendorType !== "restaurant") {
        restrictVehicles = false;
      }
    }
  }

  console.log(`[dispatchNextDriver] Finding driver for order ${orderId}, excluding: [${excludedDriverIds.join(", ")}], restrictVehicles: ${restrictVehicles}`);
  const newDriverId = await getNearestDriver(pickupLocation, excludedDriverIds, restrictVehicles);

  if (!newDriverId) {
    console.log(`[dispatchNextDriver] No available drivers left for order ${orderId}`);
    await orderRef.update({
      status: "unassigned",
      dispatchNote: "All nearby drivers have either declined, timed out, or are unavailable.",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
  }

  let vendorName = orderData.vendorName || orderData.restaurantName || "a vendor";
  let vendorLat = pickupLocation.lat;
  let vendorLng = pickupLocation.lng;
  if (vendorId && !orderData.vendorName && !orderData.restaurantName) {
    const vendorDoc = await db.collection("vendors").doc(vendorId).get();
    if (vendorDoc.exists) {
      vendorName = vendorDoc.data()?.name || "a vendor";
      vendorLat = vendorDoc.data()?.latitude || 0;
      vendorLng = vendorDoc.data()?.longitude || 0;
    }
  }

  const itemNames = (orderData.items || []).map((item: any) => item.name || "Item");

  // Create a delivery request for the chosen driver (60 seconds timeout)
  const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 60 * 1000));

  // Fetch driver profile to get details
  const driverDoc = await db.collection("driverProfiles").doc(newDriverId).get();
  const driverData = driverDoc.exists ? driverDoc.data() : null;

  // Create orderDrivers record with pending status and expiresAt timestamp
  await db.collection("orders")
    .doc(orderId)
    .collection("orderDrivers")
    .doc(newDriverId)
    .set({
      driverUserId: newDriverId,
      driverName: driverData?.name || newDriverId,
      driverPhone: driverData?.phoneNumber || "",
      vehicleModel: driverData?.vehicleModel || "",
      licensePlate: driverData?.licensePlate || "",
      status: "pending",
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

  const newRequestRef = db.collection("deliveryRequests").doc(`${orderId}_${newDriverId}`);
  await newRequestRef.set({
    orderId,
    driverId: newDriverId,
    vendorId,
    vendorName,
    customerAddress: orderData.deliveryAddress || "",
    customerLat: orderData.deliveryLat || 0,
    customerLng: orderData.deliveryLng || 0,
    vendorLat,
    vendorLng,
    estimatedDistance: 0,
    deliveryFee: orderData.deliveryFee || 0,
    orderTotal: orderData.total || 0,
    assignedItems: [],
    itemNames,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
  }, { merge: true });

  // Update order status to searching
  await orderRef.update({
    status: "searching",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[dispatchNextDriver] Created deliveryRequest ${newRequestRef.id} for driver ${newDriverId}`);
  return newDriverId;
}
