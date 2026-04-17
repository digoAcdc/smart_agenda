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
  const assertion = await new SignJWT({})
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

function normalizeGoogleSubscription(data) {
  const now = Date.now();
  const expiryMs = data?.expiryTimeMillis ? Number(data.expiryTimeMillis) : null;
  const startMs = data?.startTimeMillis ? Number(data.startTimeMillis) : null;
  const paymentState = typeof data?.paymentState === "number" ? data.paymentState : null;
  const autoRenewing = Boolean(data?.autoRenewing);
  const cancelReason = typeof data?.cancelReason === "number" ? data.cancelReason : null;

  const isPaid = paymentState === 1 || paymentState === 2;
  const isExpired = expiryMs ? expiryMs <= now : false;
  const isPremium = isPaid && !isExpired;

  let subscriptionStatus = "expired";
  if (!isPaid) {
    subscriptionStatus = "pending";
  } else if (expiryMs === null) {
    // Decisao de produto: manter premium quando o provedor nao retornar expiracao.
    subscriptionStatus = "active_unknown_expiry";
  } else if (isExpired) {
    subscriptionStatus = "expired";
  } else if (cancelReason !== null && !autoRenewing) {
    subscriptionStatus = "canceled_pending_expiry";
  } else {
    subscriptionStatus = "active";
  }

  return {
    isPremium,
    subscriptionStatus,
    expiresAt: expiryMs ? new Date(expiryMs).toISOString() : null,
    startsAt: startMs ? new Date(startMs).toISOString() : null,
    autoRenewing,
    orderId: data?.orderId ?? null,
    paymentState,
    rawResponse: data,
  };
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

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}` +
    `/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

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
        return normalizeGoogleSubscription(data);
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
