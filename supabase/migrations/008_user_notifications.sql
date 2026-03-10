-- Tabela de notificacoes push (resumo diario/semanal) para n8n + app

CREATE TABLE user_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  reference_date DATE NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  read_at TIMESTAMPTZ
);

CREATE INDEX idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_created_at ON user_notifications(created_at DESC);
CREATE INDEX idx_user_notifications_user_read ON user_notifications(user_id, read_at) WHERE read_at IS NULL;

ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notifications"
  ON user_notifications FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RPC para n8n: retorna premium users com tokens FCM
-- Usa user_subscriptions (is_premium, nao expirado) + premium_allowlist
CREATE OR REPLACE FUNCTION public.get_premium_users_with_tokens()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH premium_users AS (
    SELECT DISTINCT us.user_id
    FROM user_subscriptions us
    WHERE us.is_premium = true
      AND (us.expires_at IS NULL OR us.expires_at > now())
    UNION
    SELECT u.id
    FROM auth.users u
    INNER JOIN premium_allowlist pa ON LOWER(pa.email) = LOWER(u.email) AND pa.is_active = true
    WHERE NOT EXISTS (
      SELECT 1 FROM user_subscriptions us
      WHERE us.user_id = u.id AND us.is_premium = true
        AND (us.expires_at IS NULL OR us.expires_at > now())
    )
  )
  SELECT
    uft.user_id,
    uft.token,
    uft.platform
  FROM user_fcm_tokens uft
  INNER JOIN premium_users pu ON pu.user_id = uft.user_id;
END;
$$;
