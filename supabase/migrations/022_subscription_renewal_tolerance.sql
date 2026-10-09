-- Renovacao mensal: o Google cobra perto do vencimento e a billing-api
-- reconsulta a cada 30 min. Assinatura com renovacao automatica ligada
-- continua valendo ate 2h apos o vencimento salvo, para nao derrubar o Pro
-- (e deixar a Familia so leitura) nesse intervalo. Cancelada: sem tolerancia.
-- Regra de produto mantida (migration 015): expires_at NULL com is_premium = ativo.

CREATE OR REPLACE FUNCTION private.user_has_active_pro(p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_subscriptions us
    WHERE us.user_id = p_user
      AND us.is_premium = true
      AND (
        us.expires_at IS NULL
        OR us.expires_at > now()
        OR (us.auto_renewing AND us.expires_at > now() - interval '2 hours')
      )
  )
  OR EXISTS (
    -- Override para desenvolvimento/testes.
    SELECT 1 FROM public.premium_allowlist pa
    JOIN auth.users u ON lower(u.email) = lower(pa.email)
    WHERE u.id = p_user AND pa.is_active = true
  );
$$;

CREATE OR REPLACE FUNCTION public.get_subscription_premium_status()
RETURNS TABLE (is_premium BOOLEAN, status TEXT, expires_at TIMESTAMPTZ, product_id TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT us.is_premium, us.subscription_status, us.expires_at, us.product_id
  FROM user_subscriptions us
  WHERE us.user_id = auth.uid()
    AND us.is_premium = true
    AND (
      us.expires_at IS NULL
      OR us.expires_at > now()
      OR (us.auto_renewing AND us.expires_at > now() - interval '2 hours')
    )
  ORDER BY us.expires_at DESC NULLS FIRST
  LIMIT 1;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_subscription_premium_status() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_subscription_premium_status() TO authenticated, service_role;
