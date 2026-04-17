import dotenv from "dotenv";
import Fastify from "fastify";
import rateLimit from "@fastify/rate-limit";

import { verifySupabaseJwt, AuthError } from "./auth.js";
import { validateGoogleSubscription, GooglePlayError } from "./googlePlay.js";
import {
  createSupabaseAdminClient,
  upsertSubscription,
  logPurchaseValidation,
  SupabasePersistenceError,
} from "./supabase.js";

dotenv.config();

const requiredEnvs = [
  "PORT",
  "SUPABASE_URL",
  "SUPABASE_SERVICE_ROLE_KEY",
  "SUPABASE_JWT_SECRET",
  "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON",
  "ANDROID_PACKAGE_NAME",
  "BILLING_ALLOWED_PRODUCT_IDS",
];

for (const envName of requiredEnvs) {
  if (!process.env[envName]) {
    throw new Error(`Missing required environment variable: ${envName}`);
  }
}

const app = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || "info",
  },
});

await app.register(rateLimit, {
  global: false,
});

const supabase = createSupabaseAdminClient({
  url: process.env.SUPABASE_URL,
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
});

function maskToken(token) {
  if (!token || token.length < 8) return "***";
  return `${token.slice(0, 4)}...${token.slice(-4)}`;
}

function isValidValidateRequest(body) {
  return (
    body &&
    typeof body === "object" &&
    typeof body.productId === "string" &&
    body.productId.trim().length > 0 &&
    typeof body.purchaseToken === "string" &&
    body.purchaseToken.trim().length > 0
  );
}

const allowedProductIds = new Set(
  process.env.BILLING_ALLOWED_PRODUCT_IDS.split(",")
    .map((value) => value.trim())
    .filter(Boolean)
);

app.get("/health", async () => {
  return {
    status: "ok",
    config_ok: true,
    billing: {
      android_package_name: process.env.ANDROID_PACKAGE_NAME,
      allowed_product_ids_count: allowedProductIds.size,
    },
  };
});

app.post(
  "/validate-subscription",
  {
    config: {
      rateLimit: {
        max: Number(process.env.BILLING_RATE_LIMIT_MAX || 20),
        timeWindow: process.env.BILLING_RATE_LIMIT_WINDOW || "1 minute",
      },
    },
  },
  async (request, reply) => {
  let userId = null;
  let productId = null;
  let purchaseToken = null;
  const requestId = request.id;

  try {
    const authHeader = request.headers.authorization;
    const authData = await verifySupabaseJwt(
      authHeader,
      process.env.SUPABASE_JWT_SECRET,
      {
        issuer: process.env.SUPABASE_JWT_ISSUER || undefined,
        audience: process.env.SUPABASE_JWT_AUDIENCE || undefined,
      }
    );
    userId = authData.userId;

    const body = request.body;
    if (!isValidValidateRequest(body)) {
      return reply.code(400).send({
        error: "Invalid body. Expected { productId, purchaseToken }",
      });
    }

    productId = body.productId.trim();
    purchaseToken = body.purchaseToken.trim();
    if (!allowedProductIds.has(productId)) {
      return reply.code(400).send({ error: "Invalid productId" });
    }

    const reqLogger = request.log.child({
      requestId,
      userId,
      productId,
      purchaseToken: maskToken(purchaseToken),
      event: "validate_subscription",
    });

    const googleValidation = await validateGoogleSubscription({
      productId,
      purchaseToken,
      packageName: process.env.ANDROID_PACKAGE_NAME,
      serviceAccountJson: process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON,
      logger: reqLogger,
      maxRetries: 3,
    });

    const nowIso = new Date().toISOString();
    await upsertSubscription(supabase, {
      user_id: userId,
      product_id: productId,
      purchase_token: purchaseToken,
      order_id: googleValidation.orderId,
      platform: "android",
      store: "google_play",
      subscription_status: googleValidation.subscriptionStatus,
      is_premium: googleValidation.isPremium,
      starts_at: googleValidation.startsAt,
      expires_at: googleValidation.expiresAt,
      auto_renewing: googleValidation.autoRenewing,
      raw_response_json: googleValidation.rawResponse,
      last_validated_at: nowIso,
      updated_at: nowIso,
    });

    try {
      await logPurchaseValidation(supabase, {
        user_id: userId,
        product_id: productId,
        purchase_token: purchaseToken,
        event_type: "validate_subscription",
        request_payload: { productId, purchaseToken: maskToken(purchaseToken), requestId },
        response_payload: {
          isPremium: googleValidation.isPremium,
          subscriptionStatus: googleValidation.subscriptionStatus,
          expiresAt: googleValidation.expiresAt,
        },
        status: "success",
        error_message: null,
      });
    } catch (logError) {
      reqLogger.error(
        { err: logError.message, event: "audit_log_failed", requestId },
        "Failed to persist success audit log"
      );
    }

    reqLogger.info(
      {
        event: "validate_subscription_success",
        requestId,
        isPremium: googleValidation.isPremium,
        subscriptionStatus: googleValidation.subscriptionStatus,
        expiresAt: googleValidation.expiresAt,
      },
      "Subscription validated successfully"
    );

    return reply.code(200).send({
      isPremium: googleValidation.isPremium,
      status: googleValidation.subscriptionStatus,
      subscriptionStatus: googleValidation.subscriptionStatus,
      expiresAt: googleValidation.expiresAt,
      productId,
      source: "billing_api",
      requestId,
    });
  } catch (error) {
    request.log.error(
      {
        event: "validate_subscription_failed",
        requestId,
        err: error.message,
        userId,
        productId,
        purchaseToken: purchaseToken ? maskToken(purchaseToken) : null,
      },
      "Subscription validation failed"
    );

    if (userId && productId && purchaseToken) {
      try {
        await logPurchaseValidation(supabase, {
          user_id: userId,
          product_id: productId,
          purchase_token: purchaseToken,
          event_type: "validate_subscription",
          request_payload: { productId, purchaseToken: maskToken(purchaseToken), requestId },
          response_payload: null,
          status: "error",
          error_message: error.message,
        });
      } catch (logError) {
        request.log.error(
          { err: logError.message, event: "audit_log_failed", requestId },
          "Failed to persist validation error log"
        );
      }
    }

    if (
      error instanceof AuthError ||
      error instanceof GooglePlayError ||
      error instanceof SupabasePersistenceError
    ) {
      const publicMessage =
        error.statusCode >= 500
          ? "Validation failed temporarily. Please retry."
          : error.message;
      return reply.code(error.statusCode).send({ error: publicMessage });
    }

    return reply.code(500).send({ error: "Internal server error" });
  }
}
);

const port = Number(process.env.PORT || 3000);

app
  .listen({ host: "0.0.0.0", port })
  .then(() => {
    app.log.info(`smart-agenda-billing-api listening on 0.0.0.0:${port}`);
  })
  .catch((err) => {
    app.log.error(err, "Failed to start server");
    process.exit(1);
  });
