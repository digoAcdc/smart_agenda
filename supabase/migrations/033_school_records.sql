-- Notas e faltas por materia da grade (aba "Notas e faltas" em Aulas).
-- Mesmas regras da grade: pessoal so o dono ve (Pro envia do aparelho);
-- da Familia todos os membros veem e quem edita a agenda lanca.
-- schedule_id sem chave estrangeira: a grade pessoal sobe por substituicao
-- (apaga e insere de novo), e uma cascata apagaria as notas a cada envio.

CREATE TABLE public.school_records (
  id TEXT PRIMARY KEY,
  schedule_id TEXT NOT NULL,
  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
  owner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  child_id UUID REFERENCES public.family_children(id) ON DELETE CASCADE,
  subject TEXT NOT NULL CHECK (char_length(btrim(subject)) BETWEEN 1 AND 80),
  kind TEXT NOT NULL CHECK (kind IN ('absence', 'grade')),
  date DATE NOT NULL,
  title TEXT CHECK (title IS NULL OR char_length(title) <= 80),
  score NUMERIC(6, 2) CHECK (score IS NULL OR score >= 0),
  max_score NUMERIC(6, 2) CHECK (max_score IS NULL OR max_score > 0),
  term SMALLINT CHECK (term IS NULL OR term BETWEEN 1 AND 4),
  note TEXT CHECK (note IS NULL OR char_length(note) <= 500),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT school_records_scope CHECK (
    (owner_user_id IS NOT NULL AND family_id IS NULL AND child_id IS NULL)
    OR (owner_user_id IS NULL AND family_id IS NOT NULL)
  )
);

-- Cursor do sync da Familia (family_id + updated_at) e politicas.
CREATE INDEX school_records_family_updated_idx
  ON public.school_records(family_id, updated_at) WHERE family_id IS NOT NULL;
CREATE INDEX school_records_owner_idx
  ON public.school_records(owner_user_id) WHERE owner_user_id IS NOT NULL;
CREATE INDEX school_records_schedule_idx ON public.school_records(schedule_id);

-- Autoria, escopo imutavel, filho da mesma Familia, cursor no servidor.
CREATE OR REPLACE FUNCTION private.guard_school_record()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.created_at := COALESCE(NEW.created_at, now());
    IF NEW.child_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM family_children c
      WHERE c.id = NEW.child_id AND c.family_id = NEW.family_id
    ) THEN
      RAISE EXCEPTION 'Filho nao pertence a esta familia' USING ERRCODE = '23514';
    END IF;
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.owner_user_id := OLD.owner_user_id;
    NEW.child_id := OLD.child_id;
    NEW.schedule_id := OLD.schedule_id;
    NEW.created_by := OLD.created_by;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER school_records_guard BEFORE INSERT OR UPDATE ON public.school_records
  FOR EACH ROW EXECUTE FUNCTION private.guard_school_record();

ALTER TABLE public.school_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY school_records_personal ON public.school_records FOR ALL TO authenticated
  USING (owner_user_id = (SELECT auth.uid()))
  WITH CHECK (owner_user_id = (SELECT auth.uid()));
CREATE POLICY school_records_family_select ON public.school_records FOR SELECT TO authenticated
  USING (family_id IS NOT NULL AND private.is_family_member(family_id));
CREATE POLICY school_records_family_insert ON public.school_records FOR INSERT TO authenticated
  WITH CHECK (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id));
CREATE POLICY school_records_family_update ON public.school_records FOR UPDATE TO authenticated
  USING (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id))
  WITH CHECK (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id));

ALTER PUBLICATION supabase_realtime ADD TABLE public.school_records;

NOTIFY pgrst, 'reload schema';
