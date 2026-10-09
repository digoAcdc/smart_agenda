#!/usr/bin/env bash
# Suporte: mostra a situacao da assinatura de um cliente pelo e-mail.
# Uso: scripts/assinatura.sh cliente@email.com
set -euo pipefail

email="${1:-}"
if [[ -z "$email" || "$email" != *@* ]]; then
  echo "Uso: $0 cliente@email.com" >&2
  exit 1
fi
# Aspas simples no e-mail quebrariam o SQL.
email="${email//\'/}"

ssh root@srv1472309.hstgr.cloud \
  "docker exec -i smart_agenda_supabase-db-1 psql -U supabase_admin -d postgres -X" <<SQL
\pset footer off
\echo '== Conta'
SELECT u.id, u.email, u.created_at::date AS criada_em, u.last_sign_in_at AS ultimo_login
FROM auth.users u WHERE lower(u.email) = lower('$email');

\echo '== Pro agora (o que o app enxerga)'
SELECT private.user_has_active_pro(u.id) AS tem_pro
FROM auth.users u WHERE lower(u.email) = lower('$email');

\echo '== Assinaturas (pedido GPA = Play Console > Gestao de pedidos)'
SELECT s.order_id AS pedido, s.subscription_status AS situacao, s.is_premium AS pro,
       s.auto_renewing AS renova, s.expires_at AS vale_ate, s.last_validated_at AS conferido_em,
       (s.raw_response_json->>'testPurchase') IS NOT NULL AS compra_teste
FROM user_subscriptions s JOIN auth.users u ON u.id = s.user_id
WHERE lower(u.email) = lower('$email') ORDER BY s.updated_at DESC;

\echo '== Ultimas validacoes (erros aparecem aqui)'
SELECT v.created_at, v.event_type AS origem, v.status, v.error_message AS erro,
       v.response_payload->>'subscriptionStatus' AS situacao
FROM purchase_validations v JOIN auth.users u ON u.id = v.user_id
WHERE lower(u.email) = lower('$email') ORDER BY v.created_at DESC LIMIT 10;

\echo '== Familia'
SELECT f.name AS familia, m.role AS papel, (f.owner_id = m.user_id) AS dono,
       private.user_has_active_pro(f.owner_id) AS dono_tem_pro
FROM family_members m JOIN families f ON f.id = m.family_id JOIN auth.users u ON u.id = m.user_id
WHERE lower(u.email) = lower('$email');

\echo '== Liberacao manual (allowlist)'
SELECT email, is_active FROM premium_allowlist WHERE lower(email) = lower('$email');
SQL
