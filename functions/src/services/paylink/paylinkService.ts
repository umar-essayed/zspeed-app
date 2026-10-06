import { PaylinkClient, PaylinkApiError, PaylinkSignatureError } from "@getpayin/paylink";
import { getPaylinkConfig } from "./paylinkConfig";
import { AuditLogger } from "../logging/auditLogger";

let clientInstance: PaylinkClient | null = null;

export async function getPaylinkClient(): Promise<PaylinkClient> {
  if (clientInstance) {
    return clientInstance;
  }

  const config = await getPaylinkConfig();
  clientInstance = new PaylinkClient({
    publicToken: config.publicToken,
    hashToken: config.hashToken,
    baseUrl: config.baseUrl,
    timeoutMs: 30000,
    maxRetries: 2,
  });

  return clientInstance;
}

export interface InitInvoiceOptions {
  orderId: string;
  amount: number;
  currency?: string;
  orderTitle: string;
  customerName?: string;
  customerEmail?: string;
  customerPhone?: string;
  customerAddress?: string;
  customerCity?: string;
  userId?: string;
  isRide?: boolean;
}

export interface InitInvoiceResult {
  checkoutUrl: string;
  invoiceId: number;
  expiresAt: string;
}

export class PaylinkService {
  /**
   * Create a secure PayLink hosted checkout session for an Order or a Ride.
   */
  public static async createInvoice(options: InitInvoiceOptions): Promise<InitInvoiceResult> {
    const client = await getPaylinkClient();
    const config = await getPaylinkConfig();

    const parts = (options.customerName || "Customer").trim().split(" ");
    const firstName = parts[0] || "Valued";
    const lastName = parts.slice(1).join(" ") || "Customer";
    const email = options.customerEmail || `customer_${options.userId?.substring(0, 8) || "user"}@zspeed.app`;
    const currency = options.currency || "EGP";
    const orderAmount = options.amount.toFixed(2);

    await AuditLogger.log({
      event: "PAYLINK_INIT_REQUESTED",
      orderId: options.isRide ? undefined : options.orderId,
      rideId: options.isRide ? options.orderId : undefined,
      userId: options.userId,
      amount: options.amount,
      currency,
      status: "INFO",
      metadata: {
        orderTitle: options.orderTitle,
      },
    });

    try {
      const result = await client.invoices.create(
        {
          firstName,
          lastName,
          email,
          orderTitle: options.orderTitle,
          orderAmount,
          currency,
          address: options.customerAddress || "Cairo",
          city: options.customerCity || "Cairo",
          country: "EG",
          redirectionUrl: config.appReturnScheme,
        },
        {
          idempotencyKey: `${options.orderId}:${Date.now()}`.substring(0, 64),
        }
      );

      await AuditLogger.log({
        event: "PAYLINK_INIT_SUCCESS",
        orderId: options.isRide ? undefined : options.orderId,
        rideId: options.isRide ? options.orderId : undefined,
        userId: options.userId,
        amount: options.amount,
        currency,
        invoiceId: result.invoiceId,
        status: "SUCCESS",
        metadata: {
          expiresAt: result.expiresAt,
        },
      });

      return {
        checkoutUrl: result.checkoutUrl,
        invoiceId: result.invoiceId,
        expiresAt: result.expiresAt,
      };
    } catch (err: any) {
      await AuditLogger.log({
        event: "PAYLINK_INIT_FAILED",
        orderId: options.isRide ? undefined : options.orderId,
        rideId: options.isRide ? options.orderId : undefined,
        userId: options.userId,
        amount: options.amount,
        currency,
        status: "FAILURE",
        reasonCode: err instanceof PaylinkApiError ? `API_${err.status}` : "INIT_EXCEPTION",
        metadata: {
          error: err.message,
          errors: err instanceof PaylinkApiError ? err.errors : null,
        },
      });
      throw err;
    }
  }

  /**
   * One-click charge a vaulted Card Token for an Order or a Ride.
   */
  public static async chargeSavedCard(options: {
    cardToken: string;
    amount: number;
    currency?: string;
    product: string;
    orderId: string;
    userId: string;
    customerName?: string;
    customerEmail?: string;
    isRide?: boolean;
  }): Promise<{ invoiceId: number; paidStatus: string }> {
    const client = await getPaylinkClient();
    const parts = (options.customerName || "Customer").trim().split(" ");
    const firstName = parts[0] || "Valued";
    const lastName = parts.slice(1).join(" ") || "Customer";
    const email = options.customerEmail || `customer_${options.userId.substring(0, 8)}@zspeed.app`;
    const currency = options.currency || "EGP";
    const price = options.amount.toFixed(2);

    await AuditLogger.log({
      event: "PAYLINK_CARD_CHARGE_REQUESTED",
      orderId: options.isRide ? undefined : options.orderId,
      rideId: options.isRide ? options.orderId : undefined,
      userId: options.userId,
      amount: options.amount,
      currency,
      status: "INFO",
      metadata: {
        product: options.product,
      },
    });

    try {
      const result = await client.cards.charge(
        {
          cardToken: options.cardToken,
          initiator: "customer",
          firstName,
          lastName,
          email,
          currency,
          price,
          product: options.product,
          country: "EG",
          address: "Cairo",
          city: "Cairo",
        },
        {
          idempotencyKey: `chg_${options.orderId}:${Date.now()}`.substring(0, 64),
        }
      );

      const isPaid = result.paidStatus === "PAID";

      await AuditLogger.log({
        event: isPaid ? "PAYLINK_CARD_CHARGE_SUCCESS" : "PAYLINK_CARD_CHARGE_FAILED",
        orderId: options.isRide ? undefined : options.orderId,
        rideId: options.isRide ? options.orderId : undefined,
        userId: options.userId,
        amount: options.amount,
        currency,
        invoiceId: result.invoiceId,
        status: isPaid ? "SUCCESS" : "FAILURE",
        reasonCode: result.paidStatus,
      });

      return {
        invoiceId: result.invoiceId,
        paidStatus: result.paidStatus,
      };
    } catch (err: any) {
      await AuditLogger.log({
        event: "PAYLINK_CARD_CHARGE_FAILED",
        orderId: options.isRide ? undefined : options.orderId,
        rideId: options.isRide ? options.orderId : undefined,
        userId: options.userId,
        amount: options.amount,
        currency,
        status: "FAILURE",
        reasonCode: err instanceof PaylinkApiError ? `API_${err.status}` : "CHARGE_EXCEPTION",
        metadata: {
          error: err.message,
        },
      });
      throw err;
    }
  }

  /**
   * Tokenize a card securely server-side and discard PAN immediately.
   */
  public static async tokenizeCard(options: {
    userId: string;
    firstName: string;
    lastName: string;
    cardNumber: string;
    cardExpiryMonth: string;
    cardExpiryYear: string;
    cardCvv?: string;
  }): Promise<{ token: string; brand: string; last4: string; expMonth: number; expYear: number }> {
    const client = await getPaylinkClient();

    try {
      const result = await client.cards.tokenize({
        firstName: options.firstName,
        lastName: options.lastName,
        customerReference: options.userId,
        cardNumber: options.cardNumber,
        cardExpiryMonth: options.cardExpiryMonth,
        cardExpiryYear: options.cardExpiryYear,
        cardCvv: options.cardCvv,
        country: "EG",
        address: "Cairo",
        city: "Cairo",
      });

      const brand = result.card.brand || "Card";
      const last4 = result.card.last4 || options.cardNumber.slice(-4);
      const expMonth = result.card.expMonth || parseInt(options.cardExpiryMonth, 10);
      const expYear = result.card.expYear || parseInt(options.cardExpiryYear, 10);

      await AuditLogger.log({
        event: "PAYLINK_CARD_TOKENIZED",
        userId: options.userId,
        cardBrand: brand,
        cardLast4: last4,
        status: "SUCCESS",
      });

      return {
        token: result.token,
        brand,
        last4,
        expMonth,
        expYear,
      };
    } catch (err: any) {
      await AuditLogger.log({
        event: "PAYLINK_CARD_CHARGE_FAILED",
        userId: options.userId,
        status: "FAILURE",
        reasonCode: "TOKENIZE_FAILED",
        metadata: {
          error: err.message,
        },
      });
      throw err;
    }
  }

  /**
   * Revoke a vaulted card token.
   */
  public static async revokeToken(token: string, userId?: string): Promise<void> {
    const client = await getPaylinkClient();
    try {
      await client.cards.revoke({ cardToken: token });
      await AuditLogger.log({
        event: "PAYLINK_CARD_REVOKED",
        userId,
        status: "SUCCESS",
      });
    } catch (err: any) {
      console.warn(`[PaylinkService] Failed to revoke card token:`, err);
    }
  }

  /**
   * Verify an incoming webhook with HMAC-SHA256.
   */
  public static async verifyWebhook(body: any): Promise<any> {
    const client = await getPaylinkClient();
    try {
      return client.webhooks.verify(body);
    } catch (err) {
      if (err instanceof PaylinkSignatureError) {
        await AuditLogger.log({
          event: "PAYLINK_WEBHOOK_SIGNATURE_INVALID",
          status: "SECURITY_ALERT",
          reasonCode: "INVALID_HMAC_SIGNATURE",
        });
      }
      throw err;
    }
  }
}
