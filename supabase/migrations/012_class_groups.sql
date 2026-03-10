-- Tabelas para Turmas (class groups) e contatos (students) - plano premium
CREATE TABLE IF NOT EXISTS class_groups (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id TEXT NOT NULL REFERENCES class_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  guardian_name TEXT,
  guardian_email TEXT,
  guardian_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

-- RLS para class_groups
ALTER TABLE class_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own class_groups"
  ON class_groups FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS para students
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own students"
  ON students FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
