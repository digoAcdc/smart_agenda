-- RPC para buscar user_id por email (compartilhamento)
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

-- Tabela de compartilhamento de agenda (premium)
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

-- Dono pode gerenciar (criar, ler, deletar) seus compartilhamentos
CREATE POLICY "Owner can manage own shares"
  ON agenda_shares FOR ALL
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Receptor pode apenas ler (para saber com quem a agenda foi compartilhada)
CREATE POLICY "Receptor can read shares with me"
  ON agenda_shares FOR SELECT
  USING (auth.uid() = shared_with_id);

-- Receptor pode SELECT itens de owners que compartilharam com ele
CREATE POLICY "Receptor can read shared items"
  ON agenda_items FOR SELECT
  USING (
    user_id IN (
      SELECT owner_id FROM agenda_shares
      WHERE shared_with_id = auth.uid()
    )
  );

-- Receptor pode ler attachments de itens compartilhados
CREATE POLICY "Receptor can read shared attachments"
  ON attachments FOR SELECT
  USING (
    user_id IN (
      SELECT owner_id FROM agenda_shares
      WHERE shared_with_id = auth.uid()
    )
  );
