import { test } from "node:test";
import assert from "node:assert/strict";
import { normalizeGoogleSubscription } from "../googlePlay.js";

const NOW = Date.parse("2026-10-08T12:00:00Z");
const FUTURE = "2026-11-08T12:00:00Z";
const PAST = "2026-10-01T12:00:00Z";
const sub = (state, expiryTime, extra = {}) => ({
  subscriptionState: state,
  startTime: "2026-09-08T12:00:00Z",
  latestOrderId: "GPA.1",
  acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
  lineItems: [{ productId: "smart_agenda_premium", expiryTime, autoRenewingPlan: { autoRenewEnabled: true } }],
  ...extra,
});
const n = (data) => normalizeGoogleSubscription(data, "smart_agenda_premium", NOW);

test("ativa renovando: Pro", () => {
  const r = n(sub("SUBSCRIPTION_STATE_ACTIVE", FUTURE));
  assert.equal(r.isPremium, true);
  assert.equal(r.subscriptionStatus, "active");
  assert.equal(r.expiresAt, "2026-11-08T12:00:00.000Z");
  assert.equal(r.autoRenewing, true);
});

test("cancelada pelo usuario: Pro ate o fim do periodo pago", () => {
  const data = sub("SUBSCRIPTION_STATE_CANCELED", FUTURE);
  data.lineItems[0].autoRenewingPlan.autoRenewEnabled = false;
  const r = n(data);
  assert.equal(r.isPremium, true);
  assert.equal(r.subscriptionStatus, "canceled_pending_expiry");
  assert.equal(r.autoRenewing, false);
});

test("cancelada e vencida: sem Pro", () => {
  const r = n(sub("SUBSCRIPTION_STATE_CANCELED", PAST));
  assert.equal(r.isPremium, false);
  assert.equal(r.subscriptionStatus, "expired");
});

test("pagamento falhou, em carencia: mantem Pro", () => {
  const r = n(sub("SUBSCRIPTION_STATE_IN_GRACE_PERIOD", FUTURE));
  assert.equal(r.isPremium, true);
  assert.equal(r.subscriptionStatus, "in_grace_period");
});

test("suspensa (on hold), pausada, expirada, pendente: sem Pro", () => {
  for (const [state, status] of [
    ["SUBSCRIPTION_STATE_ON_HOLD", "on_hold"],
    ["SUBSCRIPTION_STATE_PAUSED", "paused"],
    ["SUBSCRIPTION_STATE_EXPIRED", "expired"],
    ["SUBSCRIPTION_STATE_PENDING", "pending"],
  ]) {
    const r = n(sub(state, FUTURE));
    assert.equal(r.isPremium, false, state);
    assert.equal(r.subscriptionStatus, status);
  }
});

test("sem data de expiracao nunca vira Pro", () => {
  const r = n(sub("SUBSCRIPTION_STATE_ACTIVE", undefined));
  assert.equal(r.isPremium, false);
  assert.equal(r.expiresAt, null);
});

test("compra ainda nao reconhecida e marcada para reconhecer", () => {
  const r = n(sub("SUBSCRIPTION_STATE_ACTIVE", FUTURE, { acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING" }));
  assert.equal(r.needsAcknowledgement, true);
});

test("compra de teste e identificada", () => {
  assert.equal(n(sub("SUBSCRIPTION_STATE_ACTIVE", FUTURE, { testPurchase: {} })).isTestPurchase, true);
});
