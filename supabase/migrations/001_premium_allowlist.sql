-- Allow list temporaria para simular premium ate in-app purchase
CREATE TABLE IF NOT EXISTS premium_allowlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE premium_allowlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can check own email"
  ON premium_allowlist FOR SELECT
  USING (
    auth.role() = 'authenticated'
    AND LOWER(email) = LOWER(auth.jwt()->>'email')
  );
