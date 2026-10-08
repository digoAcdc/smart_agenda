-- Modelo de Familia: perfis, familias, membros, filhos, convites e agenda
-- com escopo pessoal (owner_user_id) ou da familia (family_id).
--
-- Regras principais:
-- - Assinatura Pro pertence ao dono da familia; membros nao precisam de Pro.
-- - Limite de membros por familia (max_members, padrao 5, dono incluso). Filhos nao contam.
-- - V1: cada usuario participa de no maximo 1 familia (indice unico, removivel na V2).
-- - Papeis: admin (gerencia), editor (cria/edita/conclui), viewer (somente leitura).
-- - Familia sem Pro ativo do dono fica somente leitura. Nada e apagado automaticamente.
-- - Exclusao de itens e logica (deleted_at) para propagar entre dispositivos.

-- ---------------------------------------------------------------------------
-- Tipos
-- ---------------------------------------------------------------------------

CREATE TYPE public.family_role AS ENUM ('admin', 'editor', 'viewer');
CREATE TYPE public.family_invite_status AS ENUM ('pending', 'accepted', 'declined', 'revoked');
CREATE TYPE public.agenda_item_kind AS ENUM ('event', 'task', 'reminder');
CREATE TYPE public.agenda_subject_type AS ENUM ('none', 'family', 'child', 'member');
CREATE TYPE public.agenda_assignee_type AS ENUM ('none', 'all', 'member');

-- ---------------------------------------------------------------------------
-- Perfis
-- ---------------------------------------------------------------------------

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(
      NULLIF(TRIM(NEW.raw_user_meta_data ->> 'name'), ''),
      NULLIF(TRIM(NEW.raw_user_meta_data ->> 'full_name'), ''),
      split_part(NEW.email, '@', 1)
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();

INSERT INTO public.profiles (id, display_name)
SELECT u.id, split_part(u.email, '@', 1)
FROM auth.users u
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Familia
-- ---------------------------------------------------------------------------

CREATE TABLE public.families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  max_members INTEGER NOT NULL DEFAULT 5 CHECK (max_members >= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- V1: um dono possui no maximo 1 familia.
CREATE UNIQUE INDEX families_owner_unique ON public.families(owner_id);

CREATE TABLE public.family_members (
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.family_role NOT NULL,
  -- Como a pessoa aparece na familia (ex.: "Mamae", "Vovo"). Opcional.
  nickname TEXT CHECK (nickname IS NULL OR char_length(btrim(nickname)) BETWEEN 1 AND 40),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (family_id, user_id)
);

-- V1: cada usuario participa de no maximo 1 familia. Remover este indice na V2.
CREATE UNIQUE INDEX family_members_one_family_v1 ON public.family_members(user_id);

CREATE TABLE public.family_children (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
  birth_date DATE,
  color_hex TEXT,
  avatar_url TEXT,
  notes TEXT,
  -- Futuro: filho com conta propria.
  linked_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Arquivar preserva os eventos ligados ao filho.
  archived_at TIMESTAMPTZ
);

CREATE INDEX family_children_family_idx ON public.family_children(family_id);

CREATE TABLE public.family_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  email TEXT NOT NULL CHECK (email = lower(btrim(email)) AND position('@' IN email) > 1),
  role public.family_role NOT NULL DEFAULT 'editor',
  invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status public.family_invite_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT now() + interval '7 days',
  responded_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX family_invites_one_pending
  ON public.family_invites(family_id, email)
  WHERE status = 'pending';
CREATE INDEX family_invites_email_idx ON public.family_invites(email) WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- Helpers de permissao (schema private: nao exposto pela API REST)
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

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
      AND (us.expires_at IS NULL OR us.expires_at > now())
  )
  OR EXISTS (
    -- Override para desenvolvimento/testes.
    SELECT 1 FROM public.premium_allowlist pa
    JOIN auth.users u ON lower(u.email) = lower(pa.email)
    WHERE u.id = p_user AND pa.is_active = true
  );
$$;

CREATE OR REPLACE FUNCTION private.my_family_role(p_family UUID)
RETURNS public.family_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT fm.role FROM public.family_members fm
  WHERE fm.family_id = p_family AND fm.user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION private.is_family_member(p_family UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT private.my_family_role(p_family) IS NOT NULL;
$$;

-- Familia ativa = dono com Pro ativo.
CREATE OR REPLACE FUNCTION private.family_is_active(p_family UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT private.user_has_active_pro(f.owner_id) FROM public.families f WHERE f.id = p_family),
    false
  );
$$;

CREATE OR REPLACE FUNCTION private.can_edit_family_agenda(p_family UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT private.my_family_role(p_family) IN ('admin', 'editor')
     AND private.family_is_active(p_family);
$$;

CREATE OR REPLACE FUNCTION private.can_admin_family(p_family UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT private.my_family_role(p_family) = 'admin'
     AND private.family_is_active(p_family);
$$;

CREATE OR REPLACE FUNCTION private.shares_family_with(p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.family_members me
    JOIN public.family_members other ON other.family_id = me.family_id
    WHERE me.user_id = auth.uid() AND other.user_id = p_user
  );
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA private TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Agenda (pessoal ou da familia)
-- ---------------------------------------------------------------------------

CREATE TABLE public.agenda_groups (
  id TEXT PRIMARY KEY,
  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
  owner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color_hex TEXT,
  icon_code INTEGER,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT agenda_groups_scope CHECK ((family_id IS NULL) <> (owner_user_id IS NULL))
);

CREATE INDEX agenda_groups_family_idx ON public.agenda_groups(family_id, updated_at);
CREATE INDEX agenda_groups_owner_idx ON public.agenda_groups(owner_user_id, updated_at);

CREATE TABLE public.agenda_items (
  id TEXT PRIMARY KEY,
  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
  owner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  kind public.agenda_item_kind NOT NULL DEFAULT 'event',
  title TEXT NOT NULL CHECK (char_length(btrim(title)) > 0),
  description TEXT,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  all_day BOOLEAN NOT NULL DEFAULT false,
  timezone TEXT,
  group_id TEXT REFERENCES public.agenda_groups(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'done', 'canceled')),
  location_text TEXT,
  reminder_json TEXT,
  recurrence_json TEXT,
  -- De quem e o item: familia toda, um filho ou um membro.
  subject_type public.agenda_subject_type NOT NULL DEFAULT 'none',
  subject_child_id UUID REFERENCES public.family_children(id) ON DELETE SET NULL,
  subject_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  -- Quem e responsavel: ninguem, todos ou um membro.
  assignee_type public.agenda_assignee_type NOT NULL DEFAULT 'none',
  assignee_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Definido pelo servidor: cursor de sincronizacao incremental.
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT agenda_items_scope CHECK ((family_id IS NULL) <> (owner_user_id IS NULL))
);

CREATE INDEX agenda_items_family_start_idx ON public.agenda_items(family_id, start_at) WHERE family_id IS NOT NULL;
CREATE INDEX agenda_items_family_updated_idx ON public.agenda_items(family_id, updated_at) WHERE family_id IS NOT NULL;
CREATE INDEX agenda_items_owner_start_idx ON public.agenda_items(owner_user_id, start_at) WHERE owner_user_id IS NOT NULL;
CREATE INDEX agenda_items_owner_updated_idx ON public.agenda_items(owner_user_id, updated_at) WHERE owner_user_id IS NOT NULL;
CREATE INDEX agenda_items_child_idx ON public.agenda_items(subject_child_id) WHERE subject_child_id IS NOT NULL;

CREATE TABLE public.attachments (
  id TEXT PRIMARY KEY,
  item_id TEXT NOT NULL REFERENCES public.agenda_items(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  remote_url TEXT,
  storage_path TEXT,
  thumb_path TEXT,
  title TEXT,
  mime_type TEXT,
  size_bytes INTEGER,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX attachments_item_idx ON public.attachments(item_id);

CREATE OR REPLACE FUNCTION private.can_read_item(p_item TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agenda_items i
    WHERE i.id = p_item
      AND (i.owner_user_id = auth.uid()
           OR (i.family_id IS NOT NULL AND private.is_family_member(i.family_id)))
  );
$$;

CREATE OR REPLACE FUNCTION private.can_write_item(p_item TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agenda_items i
    WHERE i.id = p_item
      AND ((i.owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
           OR (i.family_id IS NOT NULL AND private.can_edit_family_agenda(i.family_id)))
  );
$$;

REVOKE ALL ON FUNCTION private.can_read_item(TEXT), private.can_write_item(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.can_read_item(TEXT), private.can_write_item(TEXT) TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Triggers de integridade
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_touch BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();
CREATE TRIGGER families_touch BEFORE UPDATE ON public.families
  FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();
CREATE TRIGGER family_children_touch BEFORE UPDATE ON public.family_children
  FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

-- Dono e limite nao mudam por UPDATE direto.
CREATE OR REPLACE FUNCTION private.guard_family_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.owner_id := OLD.owner_id;
    NEW.max_members := OLD.max_members;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER families_guard BEFORE UPDATE ON public.families
  FOR EACH ROW EXECUTE FUNCTION private.guard_family_update();

CREATE OR REPLACE FUNCTION private.guard_family_child()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.created_by := OLD.created_by;
    NEW.created_at := OLD.created_at;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER family_children_guard BEFORE INSERT OR UPDATE ON public.family_children
  FOR EACH ROW EXECUTE FUNCTION private.guard_family_child();

-- Autoria, escopo imutavel e coerencia de filho/membro/responsavel com a familia.
CREATE OR REPLACE FUNCTION private.guard_agenda_item()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.created_at := COALESCE(NEW.created_at, now());
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.owner_user_id := OLD.owner_user_id;
    NEW.created_by := OLD.created_by;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();

  -- Referencias anuladas por exclusao de usuario/filho viram "nenhum".
  IF NEW.subject_type = 'child' AND NEW.subject_child_id IS NULL THEN NEW.subject_type := 'none'; END IF;
  IF NEW.subject_type = 'member' AND NEW.subject_user_id IS NULL THEN NEW.subject_type := 'none'; END IF;
  IF NEW.assignee_type = 'member' AND NEW.assignee_user_id IS NULL THEN NEW.assignee_type := 'none'; END IF;
  IF NEW.subject_type <> 'child' THEN NEW.subject_child_id := NULL; END IF;
  IF NEW.subject_type <> 'member' THEN NEW.subject_user_id := NULL; END IF;
  IF NEW.assignee_type <> 'member' THEN NEW.assignee_user_id := NULL; END IF;

  IF NEW.family_id IS NULL THEN
    -- Agenda pessoal: sem filho/membro/responsavel.
    NEW.subject_type := 'none';
    NEW.assignee_type := 'none';
  ELSE
    IF NEW.subject_child_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.subject_child_id IS DISTINCT FROM OLD.subject_child_id)
       AND NOT EXISTS (SELECT 1 FROM family_children c
                       WHERE c.id = NEW.subject_child_id AND c.family_id = NEW.family_id) THEN
      RAISE EXCEPTION 'Filho nao pertence a esta familia' USING ERRCODE = '23514';
    END IF;
    IF NEW.subject_user_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id)
       AND NOT EXISTS (SELECT 1 FROM family_members m
                       WHERE m.user_id = NEW.subject_user_id AND m.family_id = NEW.family_id) THEN
      RAISE EXCEPTION 'Pessoa nao e membro desta familia' USING ERRCODE = '23514';
    END IF;
    IF NEW.assignee_user_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.assignee_user_id IS DISTINCT FROM OLD.assignee_user_id)
       AND NOT EXISTS (SELECT 1 FROM family_members m
                       WHERE m.user_id = NEW.assignee_user_id AND m.family_id = NEW.family_id) THEN
      RAISE EXCEPTION 'Responsavel nao e membro desta familia' USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.group_id IS NOT NULL
     AND (TG_OP = 'INSERT' OR NEW.group_id IS DISTINCT FROM OLD.group_id)
     AND NOT EXISTS (SELECT 1 FROM agenda_groups g
                     WHERE g.id = NEW.group_id
                       AND g.family_id IS NOT DISTINCT FROM NEW.family_id
                       AND g.owner_user_id IS NOT DISTINCT FROM NEW.owner_user_id) THEN
    RAISE EXCEPTION 'Categoria de outro escopo' USING ERRCODE = '23514';
  END IF;

  IF NEW.status = 'done' AND (TG_OP = 'INSERT' OR OLD.status <> 'done') THEN
    NEW.completed_at := now();
    NEW.completed_by := auth.uid();
  ELSIF NEW.status <> 'done' THEN
    NEW.completed_at := NULL;
    NEW.completed_by := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER agenda_items_guard BEFORE INSERT OR UPDATE ON public.agenda_items
  FOR EACH ROW EXECUTE FUNCTION private.guard_agenda_item();

CREATE OR REPLACE FUNCTION private.guard_agenda_group()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.owner_user_id := OLD.owner_user_id;
    NEW.created_by := OLD.created_by;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER agenda_groups_guard BEFORE INSERT OR UPDATE ON public.agenda_groups
  FOR EACH ROW EXECUTE FUNCTION private.guard_agenda_group();

CREATE OR REPLACE FUNCTION private.guard_attachment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
  RETURN NEW;
END;
$$;

CREATE TRIGGER attachments_guard BEFORE INSERT ON public.attachments
  FOR EACH ROW EXECUTE FUNCTION private.guard_attachment();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

-- profiles: proprio perfil + perfis de quem esta na mesma familia.
CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated
  USING (id = auth.uid() OR private.shares_family_with(id));
CREATE POLICY profiles_update ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- families: membros leem; admin renomeia. Criar/excluir via RPC.
CREATE POLICY families_select ON public.families FOR SELECT TO authenticated
  USING (private.is_family_member(id));
CREATE POLICY families_update ON public.families FOR UPDATE TO authenticated
  USING (private.can_admin_family(id)) WITH CHECK (private.can_admin_family(id));

-- family_members: membros leem. Alteracoes via RPC.
CREATE POLICY family_members_select ON public.family_members FOR SELECT TO authenticated
  USING (private.is_family_member(family_id));
-- Cada membro pode mudar o proprio apelido (role protegido por trigger abaixo).
CREATE POLICY family_members_update_self ON public.family_members FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION private.guard_family_member_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Papel/vinculo so mudam via RPC, que liga a flag smart_agenda.rpc na transacao.
  IF current_setting('smart_agenda.rpc', true) IS DISTINCT FROM 'on' THEN
    NEW.family_id := OLD.family_id;
    NEW.user_id := OLD.user_id;
    NEW.role := OLD.role;
    NEW.joined_at := OLD.joined_at;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER family_members_guard BEFORE UPDATE ON public.family_members
  FOR EACH ROW EXECUTE FUNCTION private.guard_family_member_update();

-- family_children: membros leem; admin cria/edita (arquivar = UPDATE archived_at).
CREATE POLICY family_children_select ON public.family_children FOR SELECT TO authenticated
  USING (private.is_family_member(family_id));
CREATE POLICY family_children_insert ON public.family_children FOR INSERT TO authenticated
  WITH CHECK (private.can_admin_family(family_id));
CREATE POLICY family_children_update ON public.family_children FOR UPDATE TO authenticated
  USING (private.can_admin_family(family_id)) WITH CHECK (private.can_admin_family(family_id));

-- family_invites: admin da familia le; convidado le os seus. Escrita via RPC.
CREATE POLICY family_invites_select ON public.family_invites FOR SELECT TO authenticated
  USING (
    private.my_family_role(family_id) = 'admin'
    OR email = lower(auth.jwt() ->> 'email')
  );

-- agenda_groups
CREATE POLICY agenda_groups_select ON public.agenda_groups FOR SELECT TO authenticated
  USING (owner_user_id = auth.uid()
         OR (family_id IS NOT NULL AND private.is_family_member(family_id)));
CREATE POLICY agenda_groups_insert ON public.agenda_groups FOR INSERT TO authenticated
  WITH CHECK ((owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
              OR (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id)));
CREATE POLICY agenda_groups_update ON public.agenda_groups FOR UPDATE TO authenticated
  USING ((owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
         OR (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id)))
  WITH CHECK ((owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
              OR (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id)));

-- agenda_items: dono le sempre (mesmo sem Pro, para recuperar dados);
-- escrita pessoal exige Pro; escrita na familia exige admin/editor e familia ativa.
-- Sem policy de DELETE: exclusao e logica (deleted_at).
CREATE POLICY agenda_items_select ON public.agenda_items FOR SELECT TO authenticated
  USING (owner_user_id = auth.uid()
         OR (family_id IS NOT NULL AND private.is_family_member(family_id)));
CREATE POLICY agenda_items_insert ON public.agenda_items FOR INSERT TO authenticated
  WITH CHECK ((owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
              OR (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id)));
CREATE POLICY agenda_items_update ON public.agenda_items FOR UPDATE TO authenticated
  USING ((owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
         OR (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id)))
  WITH CHECK ((owner_user_id = auth.uid() AND private.user_has_active_pro(auth.uid()))
              OR (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id)));

-- attachments herdam a permissao do item.
CREATE POLICY attachments_select ON public.attachments FOR SELECT TO authenticated
  USING (private.can_read_item(item_id));
CREATE POLICY attachments_insert ON public.attachments FOR INSERT TO authenticated
  WITH CHECK (private.can_write_item(item_id));
CREATE POLICY attachments_delete ON public.attachments FOR DELETE TO authenticated
  USING (private.can_write_item(item_id));
