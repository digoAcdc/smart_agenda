import { validateGoogleSubscription, GooglePlayError } from "./googlePlay.js";
import { logPurchaseValidation } from "./supabase.js";

// Reconsulta o Google periodicamente, sem depender do app aberto:
// renovacoes (a data salva venceria e o usuario perderia o Pro pagando),
// cancelamentos, reembolsos, carencia e suspensao.

const DAY_MS = 24 * 60 * 60 * 1000;
const STALE_MS = 12 * 60 * 60 * 1000;

/** Assinaturas que podem ter mudado no Google. */
export async function findSubscriptionsToRecheck(supabase, now = new Date()) {
  const soon = new Date(now.getTime() + DAY_MS).toISOString();
  const monthAgo = new Date(now.getTime() - 30 * DAY_MS).toISOString();
  const cols = "user_id, product_id, purchase_token, subscription_status, expires_at";

  // Com Pro e vencendo em ate 1 dia (ou ja vencida): renovou ou acabou?
  const { data: expiring, error: e1 } = await supabase
    .from("user_subscriptions")
    .select(cols)
    .eq("is_premium", true)
    .lt("expires_at", soon);
  if (e1) throw new Error(`recheck query failed: ${e1.message}`);

  // Carencia/suspensa/pendente recentes: o pagamento pode ter sido regularizado.
  const { data: unsettled, error: e2 } = await supabase
    .from("user_subscriptions")
    .select(cols)
    .in("subscription_status", ["in_grace_period", "on_hold", "pending", "paused"])
    .gt("updated_at", monthAgo);
  if (e2) throw new Error(`recheck query failed: ${e2.message}`);

  // Pro sem conferencia ha 12h: reembolso ou revogacao no meio do mes tiram
  // o acesso na hora no Google; sem isso so perceberiamos no vencimento.
  const stale = new Date(now.getTime() - STALE_MS).toISOString();
  const { data: unchecked, error: e3 } = await supabase
    .from("user_subscriptions")
    .select(cols)
    .eq("is_premium", true)
    .lt("last_validated_at", stale);
  if (e3) throw new Error(`recheck query failed: ${e3.message}`);

  const byToken = new Map();
  for (const row of [...(expiring ?? []), ...(unsettled ?? []), ...(unchecked ?? [])]) {
    byToken.set(row.purchase_token, row);
  }
  return [...byToken.values()];
}

export async function recheckSubscriptions({ supabase, env, logger }) {
  const rows = await findSubscriptionsToRecheck(supabase);
  let updated = 0;
  for (const row of rows) {
    const nowIso = new Date().toISOString();
    try {
      const result = await validateGoogleSubscription({
        productId: row.product_id,
        purchaseToken: row.purchase_token,
        packageName: env.ANDROID_PACKAGE_NAME,
        serviceAccountJson: env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON,
        logger,
        maxRetries: 2,
      });
      await updateRow(supabase, row, {
        subscription_status: result.subscriptionStatus,
        is_premium: result.isPremium,
        expires_at: result.expiresAt,
        auto_renewing: result.autoRenewing,
        order_id: result.orderId,
        raw_response_json: result.rawResponse,
        last_validated_at: nowIso,
        updated_at: nowIso,
      });
      await audit(supabase, row, "success", {
        isPremium: result.isPremium,
        subscriptionStatus: result.subscriptionStatus,
        expiresAt: result.expiresAt,
      });
      updated += 1;
    } catch (error) {
      if (error instanceof GooglePlayError && error.statusCode === 400) {
        // Token nao existe mais no Google (404/410: expirou ha muito tempo).
        await updateRow(supabase, row, {
          subscription_status: "not_found",
          is_premium: false,
          last_validated_at: nowIso,
          updated_at: nowIso,
        });
        await audit(supabase, row, "success", { isPremium: false, subscriptionStatus: "not_found" });
        updated += 1;
        continue;
      }
      // Falha temporaria: tenta de novo na proxima rodada, sem mexer no Pro.
      logger.warn({ err: error.message }, "[subscription_recheck_failed]");
      await audit(supabase, row, "error", null, error.message).catch(() => {});
    }
  }
  logger.info({ checked: rows.length, updated }, "[subscription_recheck_done]");
  return { checked: rows.length, updated };
}

async function updateRow(supabase, row, fields) {
  const { error } = await supabase
    .from("user_subscriptions")
    .update(fields)
    .eq("purchase_token", row.purchase_token)
    .eq("user_id", row.user_id);
  if (error) throw new Error(`update failed: ${error.message}`);
}

async function audit(supabase, row, status, response, errorMessage = null) {
  try {
    await logPurchaseValidation(supabase, {
      user_id: row.user_id,
      product_id: row.product_id,
      purchase_token: row.purchase_token,
      event_type: "scheduled_recheck",
      request_payload: { previousStatus: row.subscription_status, previousExpiresAt: row.expires_at },
      response_payload: response,
      status,
      error_message: errorMessage,
    });
  } catch {
    // Auditoria nao pode derrubar a revalidacao.
  }
}

/** Roda a cada [intervalMinutes]; nunca em paralelo consigo mesma. */
export function startRecheckSchedule({ supabase, env, logger, intervalMinutes }) {
  let running = false;
  const tick = async () => {
    if (running) return;
    running = true;
    try {
      await recheckSubscriptions({ supabase, env, logger });
    } catch (error) {
      logger.error({ err: error.message }, "[subscription_recheck_error]");
    } finally {
      running = false;
    }
  };
  setTimeout(tick, 30_000);
  return setInterval(tick, intervalMinutes * 60_000);
}
