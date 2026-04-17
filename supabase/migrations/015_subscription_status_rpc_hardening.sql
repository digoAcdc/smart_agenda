-- Reafirma regra de produto:
-- quando expires_at for NULL e is_premium=true, considerar assinatura premium ativa.
-- Isso evita bloquear o usuario quando a plataforma nao informar expiracao.

CREATE OR REPLACE FUNCTION public.get_subscription_premium_status()
RETURNS TABLE (is_premium BOOLEAN, status TEXT, expires_at TIMESTAMPTZ, product_id TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    us.is_premium,
    us.subscription_status,
    us.expires_at,
    us.product_id
  FROM user_subscriptions us
  WHERE us.user_id = auth.uid()
    AND us.is_premium = true
    AND (
      us.expires_at IS NULL
      OR us.expires_at > now()
    )
  ORDER BY us.expires_at DESC NULLS FIRST
  LIMIT 1;
END;
$$;
