import { initPaymentLogger } from "./paymentLogger";

export const loggerReady = (process.env.K_SERVICE || process.env.FUNCTIONS_EMULATOR) ?
  initPaymentLogger("test").catch((e: Error) => {
    console.error("Failed to init payment logger:", e);
  }) :
  Promise.resolve();
