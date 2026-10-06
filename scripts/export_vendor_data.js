/**
 * Export Vendor Data to Excel Script
 * 
 * Extracts all vendor information for a specified vendor email from Firestore
 * (including Vendor Profile, Menu Sections, Menu Items, and Orders)
 * and writes it into a formatted Excel (.xlsx) file.
 * 
 * Usage:
 *   node scripts/export_vendor_data.js --email="mody.come.back@gmail.com" --output="vendor_mody_data.xlsx"
 */

const path = require("path");
const fs = require("fs");

// Load firebase-admin
let admin;
try {
  admin = require("firebase-admin");
} catch (_) {
  try {
    admin = require(path.resolve(__dirname, "../functions/node_modules/firebase-admin"));
  } catch (err) {
    console.error("❌ Error: firebase-admin module not found.");
    process.exit(1);
  }
}

// Load ExcelJS
let ExcelJS;
try {
  ExcelJS = require("exceljs");
} catch (_) {
  console.error("❌ Error: exceljs module not found. Run: npm install exceljs");
  process.exit(1);
}

// Parse Command Line Arguments
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [key, value] = arg.split("=");
  if (key && value) {
    acc[key.replace(/^--/, "")] = value;
  }
  return acc;
}, {});

const TARGET_EMAIL = (args.email || "mody.come.back@gmail.com").trim().toLowerCase();
const OUTPUT_FILE = args.output || `vendor_${TARGET_EMAIL.replace(/[^a-zA-Z0-9]/g, "_")}_data.xlsx`;

// Service Account Initialization
const serviceAccountPath = path.join(__dirname, "../zspeed-firebase-adminsdk-fbsvc-d363073c4d.json");
if (!fs.existsSync(serviceAccountPath)) {
  console.error(`❌ Service account key not found at: ${serviceAccountPath}`);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
const cert = admin.credential ? admin.credential.cert(serviceAccount) : admin.cert(serviceAccount);
const apps = typeof admin.getApps === "function" ? admin.getApps() : (admin.apps || []);
const app = apps.length > 0 ? apps[0] : admin.initializeApp({ credential: cert });

let db;
if (typeof admin.firestore === "function") {
  db = admin.firestore();
} else {
  let getFirestore;
  try {
    getFirestore = require("firebase-admin/firestore").getFirestore;
  } catch (_) {
    getFirestore = require(path.resolve(__dirname, "../functions/node_modules/firebase-admin/firestore")).getFirestore;
  }
  db = getFirestore(app);
}

// Helper for formatting Firestore timestamps or dates
function formatDate(val) {
  if (!val) return "";
  if (typeof val.toDate === "function") {
    return val.toDate().toISOString().replace("T", " ").substring(0, 19);
  }
  if (val._seconds) {
    return new Date(val._seconds * 1000).toISOString().replace("T", " ").substring(0, 19);
  }
  if (val instanceof Date) {
    return val.toISOString().replace("T", " ").substring(0, 19);
  }
  return String(val);
}

// Helper to style sheet header
function styleHeader(worksheet) {
  const headerRow = worksheet.getRow(1);
  headerRow.font = { bold: true, color: { argb: "FFFFFF" }, size: 11 };
  headerRow.fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "1E40AF" }, // Dark blue header
  };
  headerRow.alignment = { vertical: "middle", horizontal: "center" };
  headerRow.height = 26;

  // Auto-fit column widths
  worksheet.columns.forEach((column) => {
    let maxLength = column.header ? column.header.length : 12;
    column.eachCell({ includeEmpty: false }, (cell) => {
      const valStr = cell.value ? cell.value.toString() : "";
      if (valStr.length > maxLength && valStr.length < 60) {
        maxLength = valStr.length;
      }
    });
    column.width = Math.max(maxLength + 4, 15);
  });
}

async function exportVendorData() {
  console.log(`🔍 Searching Firestore for vendor with email: ${TARGET_EMAIL}...`);

  // 1. Fetch User matching target email
  const usersSnap = await db.collection("users").get();
  let matchedUsers = [];
  usersSnap.forEach((doc) => {
    const data = doc.data();
    if (data.email && data.email.toLowerCase() === TARGET_EMAIL) {
      matchedUsers.push({ id: doc.id, ...data });
    }
  });

  console.log(`👤 Found ${matchedUsers.length} user record(s).`);

  // 2. Fetch Vendor / Store matching target email or user ID
  const vendorsSnap = await db.collection("vendors").get();
  let matchedVendors = [];
  vendorsSnap.forEach((doc) => {
    const data = doc.data();
    const emailMatch =
      (data.email && data.email.toLowerCase() === TARGET_EMAIL) ||
      (data.ownerEmail && data.ownerEmail.toLowerCase() === TARGET_EMAIL);
    const userMatch = matchedUsers.some(
      (u) => u.id === doc.id || u.id === data.ownerId || u.id === data.userId
    );
    if (emailMatch || userMatch) {
      matchedVendors.push({ id: doc.id, ...data });
    }
  });

  if (matchedVendors.length === 0 && matchedUsers.length === 0) {
    console.error(`❌ No vendor or user found matching email: ${TARGET_EMAIL}`);
    process.exit(1);
  }

  console.log(`🏪 Found ${matchedVendors.length} vendor store(s).`);

  const workbook = new ExcelJS.Workbook();
  workbook.creator = "Z_Speed Export System";
  workbook.lastModifiedBy = "Admin Script";
  workbook.created = new Date();

  // ── SHEET 1: VENDOR & USER PROFILE ──────────────────────────────────────────
  const profileSheet = workbook.addWorksheet("Vendor Profile");
  profileSheet.columns = [
    { header: "Field", key: "field", width: 25 },
    { header: "Value", key: "value", width: 50 },
    { header: "Category", key: "category", width: 20 },
  ];

  const primaryUser = matchedUsers[0] || {};
  const primaryVendor = matchedVendors[0] || {};
  const vendorId = primaryVendor.id || primaryUser.id || "";

  const profileRows = [
    { category: "Account", field: "User Email", value: primaryUser.email || TARGET_EMAIL },
    { category: "Account", field: "User ID", value: primaryUser.id || "" },
    { category: "Account", field: "Owner Name", value: primaryUser.name || "" },
    { category: "Account", field: "User Phone", value: primaryUser.phone || "" },
    { category: "Account", field: "Account Role / Type", value: primaryUser.role || primaryUser.type || "" },
    { category: "Account", field: "Account Status", value: primaryUser.status || "" },
    { category: "Account", field: "User Wallet Balance", value: primaryUser.walletBalance ?? 0 },
    
    { category: "Store Info", field: "Vendor Store ID", value: primaryVendor.id || "" },
    { category: "Store Info", field: "Store Name (En)", value: primaryVendor.name || "" },
    { category: "Store Info", field: "Store Name (Ar)", value: primaryVendor.nameAr || "" },
    { category: "Store Info", field: "Description", value: primaryVendor.description || "" },
    { category: "Store Info", field: "Vendor Type", value: primaryVendor.vendorType || "" },
    { category: "Store Info", field: "Store Phone", value: primaryVendor.phone || "" },
    { category: "Store Info", field: "Payout Phone", value: primaryVendor.payoutPhoneNumber || "" },
    { category: "Store Info", field: "Is Active", value: primaryVendor.isActive ? "Yes" : "No" },
    { category: "Store Info", field: "Is Open", value: primaryVendor.isOpen ? "Yes" : "No" },
    { category: "Store Info", field: "Rating", value: primaryVendor.rating ?? "" },
    { category: "Store Info", field: "Rating Count", value: primaryVendor.ratingCount ?? "" },
    
    { category: "Location", field: "City", value: primaryVendor.city || "" },
    { category: "Location", field: "Address", value: primaryVendor.address || "" },
    { category: "Location", field: "Latitude", value: primaryVendor.latitude ?? "" },
    { category: "Location", field: "Longitude", value: primaryVendor.longitude ?? "" },
    { category: "Location", field: "Geohash", value: primaryVendor.geohash || "" },

    { category: "Delivery Settings", field: "Delivery Fee", value: primaryVendor.deliveryFee ?? "" },
    { category: "Delivery Settings", field: "Delivery Fee Mode", value: primaryVendor.deliveryFeeMode || "" },
    { category: "Delivery Settings", field: "Delivery Radius (km)", value: primaryVendor.deliveryRadiusKm ?? "" },
    { category: "Delivery Settings", field: "Delivery Time Min (mins)", value: primaryVendor.deliveryTimeMin ?? "" },
    { category: "Delivery Settings", field: "Delivery Time Max (mins)", value: primaryVendor.deliveryTimeMax ?? "" },
    { category: "Delivery Settings", field: "Minimum Order Amount", value: primaryVendor.minimumOrder ?? 0 },

    { category: "Financials", field: "Vendor Wallet Balance", value: primaryVendor.walletBalance ?? 0 },
    { category: "Financials", field: "Total Earnings", value: primaryVendor.totalEarnings ?? 0 },

    { category: "Cuisines", field: "Cuisine Types", value: Array.isArray(primaryVendor.cuisineTypes) ? primaryVendor.cuisineTypes.join(", ") : "" },
    { category: "Media", field: "Logo URL", value: primaryVendor.logoUrl || "" },
    { category: "Media", field: "Cover Image URL", value: primaryVendor.coverImageUrl || "" },
    { category: "Timestamps", field: "Created At", value: formatDate(primaryVendor.createdAt) },
    { category: "Timestamps", field: "Updated At", value: formatDate(primaryVendor.updatedAt) },
  ];

  profileRows.forEach((r) => profileSheet.addRow(r));
  styleHeader(profileSheet);

  // ── SHEET 2: MENU SECTIONS ──────────────────────────────────────────────────
  const sectionsSheet = workbook.addWorksheet("Menu Sections");
  sectionsSheet.columns = [
    { header: "Section ID", key: "id", width: 30 },
    { header: "Section Name (En)", key: "name", width: 25 },
    { header: "Section Name (Ar)", key: "nameAr", width: 25 },
    { header: "Sort Order", key: "sortOrder", width: 12 },
    { header: "Is Active", key: "isActive", width: 12 },
    { header: "Items Count", key: "itemsCount", width: 15 },
  ];

  let menuSectionsMap = new Map();
  let totalMenuItemsCount = 0;

  if (vendorId) {
    const sectionsSnap = await db
      .collection("vendors")
      .doc(vendorId)
      .collection("menuSections")
      .orderBy("sortOrder", "asc")
      .get();

    for (const secDoc of sectionsSnap.docs) {
      const sData = secDoc.data();
      const itemsSnap = await secDoc.ref.collection("items").get();
      menuSectionsMap.set(secDoc.id, sData.name || "Uncategorized");

      sectionsSheet.addRow({
        id: secDoc.id,
        name: sData.name || "",
        nameAr: sData.nameAr || "",
        sortOrder: sData.sortOrder ?? 0,
        isActive: sData.isActive !== false ? "Yes" : "No",
        itemsCount: itemsSnap.size,
      });
    }
  }
  styleHeader(sectionsSheet);

  // ── SHEET 3: MENU ITEMS / PRODUCTS ─────────────────────────────────────────
  const itemsSheet = workbook.addWorksheet("Menu Items & Products");
  itemsSheet.columns = [
    { header: "Item ID", key: "id", width: 25 },
    { header: "Section Name", key: "sectionName", width: 20 },
    { header: "Section ID", key: "sectionId", width: 25 },
    { header: "Item Name (En)", key: "name", width: 25 },
    { header: "Item Name (Ar)", key: "nameAr", width: 25 },
    { header: "Description (En)", key: "description", width: 35 },
    { header: "Description (Ar)", key: "descriptionAr", width: 35 },
    { header: "Price (EGP)", key: "price", width: 15 },
    { header: "Discount Price", key: "discountPrice", width: 15 },
    { header: "In Stock", key: "inStock", width: 12 },
    { header: "Is Available", key: "isAvailable", width: 12 },
    { header: "Prep Time (mins)", key: "prepTime", width: 15 },
    { header: "Image URL", key: "imageUrl", width: 45 },
    { header: "Created At", key: "createdAt", width: 20 },
    { header: "Updated At", key: "updatedAt", width: 20 },
  ];

  if (vendorId) {
    const sectionsSnap = await db
      .collection("vendors")
      .doc(vendorId)
      .collection("menuSections")
      .get();

    for (const secDoc of sectionsSnap.docs) {
      const secData = secDoc.data();
      const itemsSnap = await secDoc.ref.collection("items").get();
      totalMenuItemsCount += itemsSnap.size;

      itemsSnap.forEach((itemDoc) => {
        const item = itemDoc.data();
        itemsSheet.addRow({
          id: itemDoc.id,
          sectionName: secData.name || "",
          sectionId: secDoc.id,
          name: item.name || item.title || "",
          nameAr: item.nameAr || item.titleAr || "",
          description: item.description || "",
          descriptionAr: item.descriptionAr || "",
          price: item.price ?? 0,
          discountPrice: item.discountPrice ?? item.discountedPrice ?? "",
          inStock: item.inStock !== false ? "Yes" : "No",
          isAvailable: item.isAvailable !== false ? "Yes" : "No",
          prepTime: item.prepTime || item.preparationTime || "",
          imageUrl: item.imageUrl || item.image || "",
          createdAt: formatDate(item.createdAt),
          updatedAt: formatDate(item.updatedAt),
        });
      });
    }
  }
  styleHeader(itemsSheet);

  // ── SHEET 4: ORDERS ────────────────────────────────────────────────────────
  const ordersSheet = workbook.addWorksheet("Vendor Orders");
  ordersSheet.columns = [
    { header: "Order ID", key: "id", width: 25 },
    { header: "Created At", key: "createdAt", width: 20 },
    { header: "Status", key: "status", width: 15 },
    { header: "Customer Name", key: "customerName", width: 20 },
    { header: "Customer Phone", key: "customerPhone", width: 18 },
    { header: "Delivery Address", key: "address", width: 35 },
    { header: "Total (EGP)", key: "total", width: 15 },
    { header: "Subtotal", key: "subtotal", width: 15 },
    { header: "Delivery Fee", key: "deliveryFee", width: 15 },
    { header: "Discount", key: "discount", width: 15 },
    { header: "Payment Method", key: "paymentMethod", width: 18 },
    { header: "Payment Status", key: "paymentStatus", width: 15 },
    { header: "Items Summary", key: "itemsSummary", width: 45 },
    { header: "Special Notes", key: "notes", width: 30 },
  ];

  let totalOrdersCount = 0;
  if (vendorId) {
    const ordersSnap1 = await db.collection("orders").where("vendorId", "==", vendorId).get();
    const ordersSnap2 = await db.collection("orders").where("restaurantId", "==", vendorId).get();

    const orderDocsMap = new Map();
    ordersSnap1.forEach((doc) => orderDocsMap.set(doc.id, doc));
    ordersSnap2.forEach((doc) => orderDocsMap.set(doc.id, doc));

    totalOrdersCount = orderDocsMap.size;

    orderDocsMap.forEach((doc) => {
      const order = doc.data();
      let itemsSummary = "";
      if (Array.isArray(order.items)) {
        itemsSummary = order.items
          .map((it) => `${it.name || it.title || "Item"} x${it.quantity || 1}`)
          .join("; ");
      } else if (order.itemsSummary) {
        itemsSummary = order.itemsSummary;
      }

      ordersSheet.addRow({
        id: doc.id,
        createdAt: formatDate(order.createdAt),
        status: order.status || "",
        customerName: order.customerName || order.userName || "",
        customerPhone: order.customerPhone || order.userPhone || "",
        address: order.deliveryAddress?.address || order.address || "",
        total: order.totalAmount ?? order.total ?? 0,
        subtotal: order.subtotal ?? 0,
        deliveryFee: order.deliveryFee ?? 0,
        discount: order.discountAmount ?? order.discount ?? 0,
        paymentMethod: order.paymentMethod || "",
        paymentStatus: order.paymentStatus || "",
        itemsSummary: itemsSummary,
        notes: order.instructions || order.notes || "",
      });
    });
  }
  styleHeader(ordersSheet);

  // Write Excel file
  const outputPath = path.resolve(process.cwd(), OUTPUT_FILE);
  await workbook.xlsx.writeFile(outputPath);

  console.log("\n==================================================");
  console.log("🎉 SUCCESS! Vendor data exported successfully!");
  console.log(`📄 Excel File Created: ${outputPath}`);
  console.log(`🏪 Vendor Name: ${primaryVendor.name || "N/A"}`);
  console.log(`📧 Target Email: ${TARGET_EMAIL}`);
  console.log(`📂 Menu Sections Exported: ${menuSectionsMap.size}`);
  console.log(`🍕 Menu Items Exported: ${totalMenuItemsCount}`);
  console.log(`🛒 Orders Exported: ${totalOrdersCount}`);
  console.log("==================================================\n");
}

exportVendorData().catch((err) => {
  console.error("❌ Export Failed:", err);
  process.exit(1);
});
