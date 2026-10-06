import * as admin from "firebase-admin";
admin.initializeApp();

import { initPaymentLogger } from "./services/logging/paymentLogger";

// Only initialize the logger if we are in a running environment, not during deployment discovery
if (process.env.K_SERVICE || process.env.FUNCTIONS_EMULATOR) {
  initPaymentLogger("test").catch((e: Error) => {
    console.error("Failed to init payment logger:", e);
  });
}

// Firestore triggers
export { onOrderCreated } from "./triggers/onOrderCreated";
export { onOrderStatusChanged } from "./triggers/onOrderStatusChanged";
export { onDriverAssigned } from "./triggers/onDriverAssigned";
export { onNewApplication } from "./triggers/onNewApplication";
export { onApplicationStatusChanged } from "./triggers/onApplicationStatusChanged";
export { onPaymentCreated } from "./triggers/onPaymentCreated";
export { onDeliveryRequestExpired } from "./triggers/onDeliveryRequestExpired";
export { onDeliveryRequestStatusUpdated } from "./triggers/onDeliveryRequestStatusUpdated";
export { onRideCreated } from "./triggers/onRideCreated";
export { onRideStatusChanged } from "./triggers/onRideStatusChanged";

// Callable functions
export { validatePromoCode } from "./callable/validatePromoCode";
export { sendEmailOTP, verifyEmailOTP } from "./callable/emailVerification";
export { requestDispatch } from "./callable/requestDispatch";
export { cancelDispatch } from "./callable/cancelDispatch";
export { sendBroadcastNotification } from "./callable/sendBroadcastNotification";

// Scheduled functions
export { scheduledOrderCleanup } from "./scheduled/orderCleanup";
export { dispatchTimeoutCron } from "./scheduled/dispatchTimeoutCron";
export { cleanupStaleData } from "./scheduled/cleanupStaleData";
export { createPaymentIntent } from "./callable/createPaymentIntent";

export { placeOrder } from "./callable/placeOrder";
export { onDeliveryRequestCreated } from "./triggers/onDeliveryRequestCreated";
export { onTransportCreated } from "./triggers/onTransportCreated";
export { onMenuItemUpdated } from "./triggers/onMenuItemUpdated";
export { onStoryDeleted } from "./triggers/onStoryDeleted";
export { onVendorUpdated } from "./triggers/onVendorUpdated";

// PayLink payment integration & webhooks
export { paylinkInitCheckout } from "./callable/paylinkInitCheckout";
export { paylinkChargeSavedCard } from "./callable/paylinkChargeSavedCard";
export { paylinkSaveCard, paylinkDeleteCard } from "./callable/paylinkCardManagement";
export { paylinkWebhook } from "./webhooks/paylinkWebhook";

