-- Tabelas para assinatura premium via Google Play (validacao backend)

CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  purchase_token TEXT UNIQUE NOT NULL,
  order_id TEXT,
  platform TEXT NOT NULL DEFAULT 'android',
  store TEXT NOT NULL DEFAULT 'google_play',
  subscription_status TEXT NOT NULL,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  starts_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  auto_renewing BOOLEAN DEFAULT true,
  raw_response_json JSONB,
  last_validated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_purchase_token ON user_subscriptions(purchase_token);
CREATE INDEX idx_user_subscriptions_expires_at ON user_subscriptions(expires_at) WHERE is_premium = true;

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Usuario autenticado pode SELECT apenas suas proprias assinaturas
CREATE POLICY "Users can read own subscriptions"
  ON user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT/UPDATE/DELETE apenas via Edge Function (service_role)


CREATE TABLE purchase_validations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL,
  event_type TEXT NOT NULL,
  request_payload JSONB,
  response_payload JSONB,
  status TEXT NOT NULL,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_purchase_validations_user_id ON purchase_validations(user_id);

ALTER TABLE purchase_validations ENABLE ROW LEVEL SECURITY;

-- Usuario pode ler apenas suas proprias validacoes (auditoria)
CREATE POLICY "Users can read own validations"
  ON purchase_validations FOR SELECT
  USING (auth.uid() = user_id);


-- RPC para consultar status premium por assinatura (PlanServiceImpl usa + fallback allowlist)
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
    AND (us.expires_at IS NULL OR us.expires_at > now())
  ORDER BY us.expires_at DESC NULLS FIRST
  LIMIT 1;
END;
$$;
