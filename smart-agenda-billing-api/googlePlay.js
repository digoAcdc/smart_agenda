import { importPKCS8, SignJWT } from "jose";

export class GooglePlayError extends Error {
  constructor(message, statusCode = 502) {
    super(message);
    this.name = "GooglePlayError";
    this.statusCode = statusCode;
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseServiceAccount(serviceAccountJson) {
  try {
    const parsed = JSON.parse(serviceAccountJson);
    if (!parsed?.client_email || !parsed?.private_key) {
      throw new Error("Invalid service account format");
    }
    return parsed;
  } catch {
    throw new GooglePlayError("Invalid GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", 500);
  }
}

async function getGoogleAccessToken(serviceAccountJson) {
  const serviceAccount = parseServiceAccount(serviceAccountJson);
  const privateKey = serviceAccount.private_key.replace(/\\n/g, "\n");

  const key = await importPKCS8(privateKey, "RS256");
  // Sem "scope" o Google recusa a troca do JWT (invalid_scope).
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/androidpublisher",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!tokenResponse.ok) {
    throw new GooglePlayError("Failed to authenticate with Google OAuth", 502);
  }

  const tokenPayload = await tokenResponse.json();
  if (!tokenPayload?.access_token) {
    throw new GooglePlayError("Missing Google access token", 502);
  }

  return tokenPayload.access_token;
}

/**
 * Traduz a resposta de purchases.subscriptionsv2 para o formato salvo em
 * user_subscriptions. O Google informa o estado explicitamente:
 * https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2
 *
 * Com acesso: ACTIVE, CANCELED (ate expirar) e IN_GRACE_PERIOD (pagamento
 * falhou e o Google ainda tenta cobrar). Sem acesso: ON_HOLD, PAUSED,
 * EXPIRED, PENDING, PENDING_PURCHASE_CANCELED.
 */
export function normalizeGoogleSubscription(data, productId, now = Date.now()) {
  const lineItems = Array.isArray(data?.lineItems) ? data.lineItems : [];
  const item =
    lineItems.find((li) => li?.productId === productId) ?? lineItems[0] ?? null;
  const expiryMs = item?.expiryTime ? Date.parse(item.expiryTime) : null;
  const startMs = data?.startTime ? Date.parse(data.startTime) : null;
  const autoRenewing = Boolean(item?.autoRenewingPlan?.autoRenewEnabled);
  const state = data?.subscriptionState ?? "SUBSCRIPTION_STATE_UNSPECIFIED";
  const notExpired = expiryMs !== null && expiryMs > now;

  const statusByState = {
    SUBSCRIPTION_STATE_ACTIVE: "active",
    SUBSCRIPTION_STATE_CANCELED: notExpired ? "canceled_pending_expiry" : "expired",
    SUBSCRIPTION_STATE_IN_GRACE_PERIOD: "in_grace_period",
    SUBSCRIPTION_STATE_ON_HOLD: "on_hold",
    SUBSCRIPTION_STATE_PAUSED: "paused",
    SUBSCRIPTION_STATE_EXPIRED: "expired",
    SUBSCRIPTION_STATE_PENDING: "pending",
    SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED: "pending_canceled",
  };
  const subscriptionStatus = statusByState[state] ?? "unknown";
  const isPremium =
    notExpired &&
    ["active", "canceled_pending_expiry", "in_grace_period"].includes(subscriptionStatus);

  return {
    isPremium,
    subscriptionStatus,
    expiresAt: expiryMs ? new Date(expiryMs).toISOString() : null,
    startsAt: startMs ? new Date(startMs).toISOString() : null,
    autoRenewing,
    orderId: data?.latestOrderId ?? null,
    needsAcknowledgement: data?.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING",
    isTestPurchase: Boolean(data?.testPurchase),
    rawResponse: data,
  };
}

async function acknowledgeSubscription({ base, productId, purchaseToken, accessToken, logger }) {
  const ackUrl =
    `${base}/purchases/subscriptions/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
  try {
    const res = await fetch(ackUrl, {
      method: "POST",
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: "{}",
    });
    logger.info({ statusCode: res.status }, "[subscription_acknowledge]");
  } catch (error) {
    logger.warn({ error: error.message }, "[subscription_acknowledge_failed]");
  }
}

export async function validateGoogleSubscription({
  productId,
  purchaseToken,
  packageName,
  serviceAccountJson,
  logger,
  maxRetries = 3,
}) {
  const accessToken = await getGoogleAccessToken(serviceAccountJson);

  const base =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}`;
  const url = `${base}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;

  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
    try {
      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        const result = normalizeGoogleSubscription(data, productId);
        if (result.needsAcknowledgement && result.isPremium) {
          // Garantia: o app reconhece a compra, mas se ele falhar o Google
          // reembolsa em 3 dias. Reconhecer aqui tambem evita isso.
          await acknowledgeSubscription({ base, productId, purchaseToken, accessToken, logger });
        }
        return result;
      }

      if (response.status >= 500 && attempt < maxRetries) {
        logger.warn({ attempt, statusCode: response.status }, "Google API temporary failure, retrying");
        await sleep(300 * attempt);
        continue;
      }

      if (response.status === 404) {
        throw new GooglePlayError("Purchase not found in Google Play", 400);
      }

      throw new GooglePlayError(`Google Play validation failed (status ${response.status})`, 502);
    } catch (error) {
      lastError = error;
      if (attempt < maxRetries) {
        logger.warn({ attempt, error: error.message }, "Google API call failed, retrying");
        await sleep(300 * attempt);
        continue;
      }
    }
  }

  if (lastError instanceof GooglePlayError) {
    throw lastError;
  }
  throw new GooglePlayError("Failed to validate subscription with Google Play", 502);
}
