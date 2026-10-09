import { test } from "node:test";
import assert from "node:assert/strict";
import { findSubscriptionsToRecheck } from "../revalidation.js";

// Supabase falso: registra os filtros e devolve linhas por consulta.
function fakeSupabase(results) {
  const calls = [];
  let i = 0;
  const builder = () => {
    const filters = [];
    const q = {
      select: () => q,
      eq: (c, v) => (filters.push(["eq", c, v]), q),
      lt: (c, v) => (filters.push(["lt", c, v]), q),
      gt: (c, v) => (filters.push(["gt", c, v]), q),
      in: (c, v) => (filters.push(["in", c, v]), q),
      then: (resolve) => {
        calls.push(filters);
        resolve({ data: results[i++] ?? [], error: null });
      },
    };
    return q;
  };
  return { calls, from: () => builder() };
}

test("busca Pro vencendo, pendencias e Pro sem conferencia recente, sem duplicar token", async () => {
  const sb = fakeSupabase([
    [{ purchase_token: "a" }, { purchase_token: "b" }],
    [{ purchase_token: "b" }, { purchase_token: "c" }],
    [{ purchase_token: "c" }, { purchase_token: "d" }],
  ]);
  const now = new Date("2026-10-08T12:00:00Z");
  const rows = await findSubscriptionsToRecheck(sb, now);

  assert.deepEqual(rows.map((r) => r.purchase_token).sort(), ["a", "b", "c", "d"]);
  assert.deepEqual(sb.calls[0], [
    ["eq", "is_premium", true],
    ["lt", "expires_at", "2026-10-09T12:00:00.000Z"],
  ]);
  assert.deepEqual(sb.calls[1][0], ["in", "subscription_status", ["in_grace_period", "on_hold", "pending", "paused"]]);
  // Reembolso no meio do mes: Pro conferido ha mais de 12h volta para a fila.
  assert.deepEqual(sb.calls[2], [
    ["eq", "is_premium", true],
    ["lt", "last_validated_at", "2026-10-08T00:00:00.000Z"],
  ]);
});
