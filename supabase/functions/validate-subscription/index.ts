import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface RequestBody {
  productId: string;
  purchaseToken: string;
  orderId?: string;
  packageName: string;
  purchaseTime?: number;
  platform?: string;
  purchaseState?: number;
}

interface GoogleSubscriptionPurchase {
  expiryTimeMillis?: string;
  autoRenewing?: boolean;
  paymentState?: number;
  cancelReason?: number;
  orderId?: string;
  startTimeMillis?: string;
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status: number) {
  return jsonResponse({ error: message }, status);
}

async function getGoogleAccessToken(): Promise<string> {
  const jsonStr = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  if (!jsonStr) {
    throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON not configured");
  }
  const cred = JSON.parse(jsonStr) as {
    client_email: string;
    private_key: string;
  };
  const key = await jose.importPKCS8(
    cred.private_key.replace(/\\n/g, "\n"),
    "RS256"
  );
  const jwt = await new jose.SignJWT({})
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(cred.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setSubject(cred.client_email)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    console.error("Google OAuth error:", text);
    throw new Error("Failed to get Google access token");
  }
  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

async function validateWithGooglePlay(
  packageName: string,
  productId: string,
  purchaseToken: string,
  accessToken: string
): Promise<GoogleSubscriptionPurchase> {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    const text = await res.text();
    console.error("Google Play API error:", res.status, text);
    throw new Error(`Google Play validation failed: ${res.status}`);
  }
  return (await res.json()) as GoogleSubscriptionPurchase;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.replace("Bearer ", "");
  if (!token) {
    return errorResponse("Missing Authorization header", 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Supabase env not configured");
    return errorResponse("Server configuration error", 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return errorResponse("Invalid or expired token", 401);
  }

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { productId, purchaseToken, orderId, packageName } = body;
  if (!productId || !purchaseToken || !packageName) {
    return errorResponse("Missing required fields: productId, purchaseToken, packageName", 400);
  }

  const eventType = "validate_subscription";
  const requestPayload = {
    productId,
    purchaseToken,
    orderId: orderId ?? null,
    packageName,
    purchaseTime: body.purchaseTime ?? null,
    platform: body.platform ?? "android",
    purchaseState: body.purchaseState ?? null,
  };

  try {
    const accessToken = await getGoogleAccessToken();
    const purchase = await validateWithGooglePlay(
      packageName,
      productId,
      purchaseToken,
      accessToken
    );

    const expiryMs = purchase.expiryTimeMillis
      ? parseInt(purchase.expiryTimeMillis, 10)
      : null;
    const startMs = purchase.startTimeMillis
      ? parseInt(purchase.startTimeMillis, 10)
      : null;
    const expiresAt = expiryMs
      ? new Date(expiryMs).toISOString()
      : null;
    const startsAt = startMs
      ? new Date(startMs).toISOString()
      : null;

    const paymentState = purchase.paymentState ?? 0;
    const isPaid = paymentState === 1 || paymentState === 2;
    const isPremium = isPaid && (!expiresAt || new Date(expiresAt) > new Date());
    const subscriptionStatus = isPremium ? "active" : paymentState === 0 ? "pending" : "expired";

    const row = {
      user_id: user.id,
      product_id: productId,
      purchase_token: purchaseToken,
      order_id: orderId ?? purchase.orderId ?? null,
      platform: "android",
      store: "google_play",
      subscription_status: subscriptionStatus,
      is_premium: isPremium,
      starts_at: startsAt,
      expires_at: expiresAt,
      auto_renewing: purchase.autoRenewing ?? false,
      raw_response_json: purchase as unknown as object,
      last_validated_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const { data: existing } = await supabase
      .from("user_subscriptions")
      .select("id, user_id, is_premium, expires_at, subscription_status")
      .eq("purchase_token", purchaseToken)
      .maybeSingle();

    if (existing) {
      if (existing.user_id !== user.id) {
        return errorResponse("Purchase already associated with another account", 409);
      }
      await supabase
        .from("user_subscriptions")
        .update({
          subscription_status: row.subscription_status,
          is_premium: row.is_premium,
          expires_at: row.expires_at,
          auto_renewing: row.auto_renewing,
          raw_response_json: row.raw_response_json,
          last_validated_at: row.last_validated_at,
          updated_at: row.updated_at,
        })
        .eq("purchase_token", purchaseToken);
    } else {
      await supabase.from("user_subscriptions").insert(row);
    }

    await supabase.from("purchase_validations").insert({
      user_id: user.id,
      product_id: productId,
      purchase_token: purchaseToken,
      event_type: eventType,
      request_payload: requestPayload,
      response_payload: { isPremium, subscriptionStatus, expiresAt },
      status: "success",
      error_message: null,
    });

    return jsonResponse({
      isPremium,
      status: subscriptionStatus,
      expiresAt,
      productId,
      source: "subscription",
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Validation failed";
    console.error("validate-subscription error:", msg);

    try {
      await supabase.from("purchase_validations").insert({
        user_id: user.id,
        product_id: productId,
        purchase_token: purchaseToken,
        event_type: eventType,
        request_payload: requestPayload,
        response_payload: null,
        status: "error",
        error_message: msg,
      });
    } catch (logErr) {
      console.error("Failed to log validation error:", logErr);
    }

    return errorResponse(msg, 500);
  }
});
