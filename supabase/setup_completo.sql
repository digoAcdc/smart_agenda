-- ============================================================
-- Smart Agenda - Setup completo do Supabase
-- Execute este script no SQL Editor do seu projeto Supabase
-- (Dashboard > SQL Editor > New query > Cole e Execute)
-- ============================================================

-- 1. Allow list temporaria para simular premium ate in-app purchase
CREATE TABLE IF NOT EXISTS premium_allowlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE premium_allowlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can check own email" ON premium_allowlist;
CREATE POLICY "Authenticated users can check own email"
  ON premium_allowlist FOR SELECT
  USING (
    auth.role() = 'authenticated'
    AND LOWER(email) = LOWER(auth.jwt()->>'email')
  );

-- 2. Tabelas de dados para plano premium
CREATE TABLE IF NOT EXISTS agenda_groups (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color_hex TEXT,
  icon_code INTEGER,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS agenda_items (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  all_day BOOLEAN DEFAULT false,
  timezone TEXT,
  group_id TEXT REFERENCES agenda_groups(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pending',
  location_text TEXT,
  reminder_json TEXT,
  recurrence_json TEXT,
  source TEXT DEFAULT 'local',
  sync_state TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS attachments (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES agenda_items(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  local_path TEXT,
  remote_url TEXT,
  thumb_path TEXT,
  title TEXT,
  mime_type TEXT,
  size_bytes INTEGER,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS class_schedule_slots (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL,
  start_minutes INTEGER NOT NULL,
  end_minutes INTEGER NOT NULL,
  subject TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

-- RLS para agenda_groups
ALTER TABLE agenda_groups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own groups" ON agenda_groups;
CREATE POLICY "Users can manage own groups"
  ON agenda_groups FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para agenda_items
ALTER TABLE agenda_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own items" ON agenda_items;
CREATE POLICY "Users can manage own items"
  ON agenda_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para attachments
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own attachments" ON attachments;
CREATE POLICY "Users can manage own attachments"
  ON attachments FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para class_schedule_slots
ALTER TABLE class_schedule_slots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own slots" ON class_schedule_slots;
CREATE POLICY "Users can manage own slots"
  ON class_schedule_slots FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 3. Bucket para imagens/attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Users can manage own attachments" ON storage.objects;
CREATE POLICY "Users can manage own attachments"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- 4. Compartilhamento de agenda (premium)
CREATE OR REPLACE FUNCTION public.get_user_id_by_email(email_input text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result uuid;
BEGIN
  SELECT id INTO result FROM auth.users WHERE LOWER(email) = LOWER(email_input) LIMIT 1;
  RETURN result;
END;
$$;

CREATE TABLE IF NOT EXISTS agenda_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shared_with_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_email TEXT NOT NULL,
  shared_with_email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(owner_id, shared_with_id)
);

ALTER TABLE agenda_shares ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner can manage own shares"
  ON agenda_shares FOR ALL
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Receptor can read shares with me"
  ON agenda_shares FOR SELECT
  USING (auth.uid() = shared_with_id);

CREATE POLICY "Receptor can read shared items"
  ON agenda_items FOR SELECT
  USING (
    user_id IN (
      SELECT owner_id FROM agenda_shares
      WHERE shared_with_id = auth.uid()
    )
  );

CREATE POLICY "Receptor can read shared attachments"
  ON attachments FOR SELECT
  USING (
    user_id IN (
      SELECT owner_id FROM agenda_shares
      WHERE shared_with_id = auth.uid()
    )
  );

-- 5. Seed: adiciona email na allow list premium
INSERT INTO premium_allowlist (email, is_active)
VALUES ('barbosa.silveira@gmail.com', true)
ON CONFLICT (email) DO UPDATE SET is_active = true;

-- ============================================================
-- Verificacao: rode SELECT * FROM premium_allowlist;
-- Verificacao: rode SELECT * FROM agenda_shares;
-- Deve mostrar barbosa.silveira@gmail.com
-- ============================================================
