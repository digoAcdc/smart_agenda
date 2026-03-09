import { createClient } from "@supabase/supabase-js";

export class SupabasePersistenceError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.name = "SupabasePersistenceError";
    this.statusCode = statusCode;
  }
}

export function createSupabaseAdminClient({ url, serviceRoleKey }) {
  return createClient(url, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export async function getSubscriptionByToken(client, purchaseToken) {
  const { data, error } = await client
    .from("user_subscriptions")
    .select("user_id, purchase_token")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();

  if (error) {
    throw new SupabasePersistenceError("Failed to read existing subscription");
  }

  return data;
}

export async function upsertSubscription(client, row) {
  const existing = await getSubscriptionByToken(client, row.purchase_token);
  if (existing && existing.user_id !== row.user_id) {
    throw new SupabasePersistenceError(
      "purchase_token already associated with another user",
      409
    );
  }

  const updatableFields = {
    product_id: row.product_id,
    order_id: row.order_id,
    platform: row.platform,
    store: row.store,
    subscription_status: row.subscription_status,
    is_premium: row.is_premium,
    starts_at: row.starts_at,
    expires_at: row.expires_at,
    auto_renewing: row.auto_renewing,
    raw_response_json: row.raw_response_json,
    last_validated_at: row.last_validated_at,
    updated_at: row.updated_at,
  };

  if (existing) {
    const { error } = await client
      .from("user_subscriptions")
      .update(updatableFields)
      .eq("purchase_token", row.purchase_token)
      .eq("user_id", row.user_id);

    if (error) {
      throw new SupabasePersistenceError("Failed to update subscription");
    }
    return;
  }

  const { error } = await client.from("user_subscriptions").insert(row);
  if (!error) return;

  // Tratamento de corrida: outro request pode ter inserido o mesmo token em paralelo.
  if (error.code === "23505") {
    const fresh = await getSubscriptionByToken(client, row.purchase_token);
    if (fresh && fresh.user_id === row.user_id) {
      const { error: updateError } = await client
        .from("user_subscriptions")
        .update(updatableFields)
        .eq("purchase_token", row.purchase_token)
        .eq("user_id", row.user_id);
      if (updateError) {
        throw new SupabasePersistenceError("Failed to update subscription after conflict");
      }
      return;
    }
    throw new SupabasePersistenceError(
      "purchase_token already associated with another user",
      409
    );
  }

  throw new SupabasePersistenceError("Failed to insert subscription");
}

export async function logPurchaseValidation(client, logRow) {
  const { error } = await client.from("purchase_validations").insert(logRow);
  if (error) {
    throw new SupabasePersistenceError("Failed to log validation event");
  }
}
