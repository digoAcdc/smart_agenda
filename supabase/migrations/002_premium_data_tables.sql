-- Tabelas de dados para plano premium (espelham estrutura Drift local)

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
CREATE POLICY "Users can manage own groups"
  ON agenda_groups FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para agenda_items
ALTER TABLE agenda_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own items"
  ON agenda_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para attachments
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own attachments"
  ON attachments FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para class_schedule_slots
ALTER TABLE class_schedule_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own slots"
  ON class_schedule_slots FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
