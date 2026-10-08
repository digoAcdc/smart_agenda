-- RPCs da Familia (criar, convidar, aceitar, papeis, sair, excluir),
-- contexto da familia para o app, Realtime e Storage com escopo de familia.

-- ---------------------------------------------------------------------------
-- Contexto
-- ---------------------------------------------------------------------------

-- Tudo que o app precisa para decidir a experiencia do usuario logado.
CREATE OR REPLACE FUNCTION public.get_my_family_context()
RETURNS TABLE (
  has_pro BOOLEAN,
  family_id UUID,
  family_name TEXT,
  my_role public.family_role,
  is_owner BOOLEAN,
  family_is_active BOOLEAN,
  member_count INTEGER,
  max_members INTEGER,
  pending_invites INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT
    private.user_has_active_pro(v_uid),
    f.id,
    f.name,
    fm.role,
    f.owner_id = v_uid,
    private.family_is_active(f.id),
    (SELECT count(*)::int FROM family_members x WHERE x.family_id = f.id),
    f.max_members,
    (SELECT count(*)::int FROM family_invites i
      WHERE i.family_id = f.id AND i.status = 'pending' AND i.expires_at > now())
  FROM (SELECT 1) one
  LEFT JOIN family_members fm ON fm.user_id = v_uid
  LEFT JOIN families f ON f.id = fm.family_id
  LIMIT 1;
END;
$$;

-- ---------------------------------------------------------------------------
-- Criar / excluir familia
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_family(p_name TEXT, p_nickname TEXT DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_family UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado' USING ERRCODE = '28000';
  END IF;
  IF NOT private.user_has_active_pro(v_uid) THEN
    RAISE EXCEPTION 'Criar uma Familia requer o plano Pro' USING ERRCODE = 'P0001', HINT = 'pro_required';
  END IF;
  IF EXISTS (SELECT 1 FROM family_members WHERE user_id = v_uid) THEN
    RAISE EXCEPTION 'Voce ja participa de uma Familia' USING ERRCODE = 'P0001', HINT = 'already_in_family';
  END IF;

  INSERT INTO families (name, owner_id) VALUES (btrim(p_name), v_uid) RETURNING id INTO v_family;
  INSERT INTO family_members (family_id, user_id, role, nickname)
  VALUES (v_family, v_uid, 'admin', NULLIF(btrim(p_nickname), ''));
  RETURN v_family;
END;
$$;

-- Exclusao explicita pelo dono. Nunca automatica.
CREATE OR REPLACE FUNCTION public.delete_family(p_family UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM families WHERE id = p_family AND owner_id = auth.uid()) THEN
    RAISE EXCEPTION 'Somente o dono pode excluir a Familia' USING ERRCODE = '42501';
  END IF;
  DELETE FROM families WHERE id = p_family;
END;
$$;

-- ---------------------------------------------------------------------------
-- Convites
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.invite_family_member(
  p_family UUID,
  p_email TEXT,
  p_role public.family_role DEFAULT 'editor'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email TEXT := lower(btrim(p_email));
  v_max INTEGER;
  v_used INTEGER;
  v_invite UUID;
BEGIN
  IF NOT private.can_admin_family(p_family) THEN
    RAISE EXCEPTION 'Somente administradores de uma Familia ativa podem convidar' USING ERRCODE = '42501';
  END IF;
  IF v_email IS NULL OR position('@' IN v_email) < 2 THEN
    RAISE EXCEPTION 'E-mail invalido' USING ERRCODE = '22023';
  END IF;
  IF v_email = lower(auth.jwt() ->> 'email') THEN
    RAISE EXCEPTION 'Voce ja faz parte desta Familia' USING ERRCODE = 'P0001';
  END IF;
  IF EXISTS (
    SELECT 1 FROM family_members m JOIN auth.users u ON u.id = m.user_id
    WHERE m.family_id = p_family AND lower(u.email) = v_email
  ) THEN
    RAISE EXCEPTION 'Esta pessoa ja faz parte da Familia' USING ERRCODE = 'P0001', HINT = 'already_member';
  END IF;

  -- Serializa convites concorrentes da mesma familia.
  SELECT max_members INTO v_max FROM families WHERE id = p_family FOR UPDATE;

  -- Expira convites antigos e substitui um pendente para o mesmo e-mail.
  UPDATE family_invites SET status = 'revoked', responded_at = now()
  WHERE family_id = p_family AND status = 'pending'
    AND (expires_at <= now() OR email = v_email);

  SELECT (SELECT count(*) FROM family_members WHERE family_id = p_family)
       + (SELECT count(*) FROM family_invites WHERE family_id = p_family AND status = 'pending')
  INTO v_used;
  IF v_used >= v_max THEN
    RAISE EXCEPTION 'Limite de % pessoas na Familia atingido', v_max USING ERRCODE = 'P0001', HINT = 'member_limit';
  END IF;

  INSERT INTO family_invites (family_id, email, role, invited_by)
  VALUES (p_family, v_email, p_role, auth.uid())
  RETURNING id INTO v_invite;
  RETURN v_invite;
END;
$$;

-- Convites pendentes para o e-mail do usuario logado (com nome da familia e de quem convidou).
CREATE OR REPLACE FUNCTION public.list_my_family_invites()
RETURNS TABLE (
  invite_id UUID,
  family_id UUID,
  family_name TEXT,
  role public.family_role,
  invited_by_name TEXT,
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT i.id, f.id, f.name, i.role, p.display_name, i.created_at, i.expires_at
  FROM family_invites i
  JOIN families f ON f.id = i.family_id
  LEFT JOIN profiles p ON p.id = i.invited_by
  WHERE i.email = lower(auth.jwt() ->> 'email')
    AND i.status = 'pending'
    AND i.expires_at > now()
  ORDER BY i.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.accept_family_invite(p_invite UUID, p_nickname TEXT DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_inv family_invites%ROWTYPE;
  v_max INTEGER;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_inv FROM family_invites WHERE id = p_invite FOR UPDATE;
  IF NOT FOUND OR v_inv.email <> lower(auth.jwt() ->> 'email') THEN
    RAISE EXCEPTION 'Convite nao encontrado' USING ERRCODE = 'P0002';
  END IF;
  IF v_inv.status <> 'pending' OR v_inv.expires_at <= now() THEN
    RAISE EXCEPTION 'Este convite nao esta mais valido' USING ERRCODE = 'P0001', HINT = 'invite_invalid';
  END IF;
  IF NOT private.family_is_active(v_inv.family_id) THEN
    RAISE EXCEPTION 'A assinatura desta Familia nao esta ativa' USING ERRCODE = 'P0001', HINT = 'family_inactive';
  END IF;
  IF EXISTS (SELECT 1 FROM family_members WHERE user_id = v_uid) THEN
    RAISE EXCEPTION 'Voce ja participa de uma Familia' USING ERRCODE = 'P0001', HINT = 'already_in_family';
  END IF;

  SELECT max_members INTO v_max FROM families WHERE id = v_inv.family_id FOR UPDATE;
  IF (SELECT count(*) FROM family_members WHERE family_id = v_inv.family_id) >= v_max THEN
    RAISE EXCEPTION 'Limite de % pessoas na Familia atingido', v_max USING ERRCODE = 'P0001', HINT = 'member_limit';
  END IF;

  INSERT INTO family_members (family_id, user_id, role, nickname)
  VALUES (v_inv.family_id, v_uid, v_inv.role, NULLIF(btrim(p_nickname), ''));
  UPDATE family_invites SET status = 'accepted', responded_at = now() WHERE id = p_invite;
  RETURN v_inv.family_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decline_family_invite(p_invite UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE family_invites SET status = 'declined', responded_at = now()
  WHERE id = p_invite AND status = 'pending' AND email = lower(auth.jwt() ->> 'email');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite nao encontrado' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_family_invite(p_invite UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_family UUID;
BEGIN
  SELECT family_id INTO v_family FROM family_invites WHERE id = p_invite AND status = 'pending';
  IF v_family IS NULL OR private.my_family_role(v_family) IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Convite nao encontrado' USING ERRCODE = 'P0002';
  END IF;
  UPDATE family_invites SET status = 'revoked', responded_at = now() WHERE id = p_invite;
END;
$$;

-- ---------------------------------------------------------------------------
-- Membros
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.change_family_member_role(
  p_family UUID,
  p_user UUID,
  p_role public.family_role
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  IF NOT private.can_admin_family(p_family) THEN
    RAISE EXCEPTION 'Somente administradores podem alterar permissoes' USING ERRCODE = '42501';
  END IF;
  IF EXISTS (SELECT 1 FROM families WHERE id = p_family AND owner_id = p_user) THEN
    RAISE EXCEPTION 'O dono da Familia e sempre administrador' USING ERRCODE = 'P0001', HINT = 'owner_role';
  END IF;

  PERFORM set_config('smart_agenda.rpc', 'on', true);
  UPDATE family_members SET role = p_role WHERE family_id = p_family AND user_id = p_user;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  PERFORM set_config('smart_agenda.rpc', 'off', true);
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Membro nao encontrado' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

-- Admin remove membro. Permitido mesmo com a Familia inativa (privacidade).
CREATE OR REPLACE FUNCTION public.remove_family_member(p_family UUID, p_user UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF private.my_family_role(p_family) IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Somente administradores podem remover membros' USING ERRCODE = '42501';
  END IF;
  IF EXISTS (SELECT 1 FROM families WHERE id = p_family AND owner_id = p_user) THEN
    RAISE EXCEPTION 'O dono nao pode ser removido da Familia' USING ERRCODE = 'P0001', HINT = 'owner_role';
  END IF;
  DELETE FROM family_members WHERE family_id = p_family AND user_id = p_user;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Membro nao encontrado' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

-- Membro sai por conta propria. O dono exclui a Familia em vez de sair.
CREATE OR REPLACE FUNCTION public.leave_family(p_family UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM families WHERE id = p_family AND owner_id = auth.uid()) THEN
    RAISE EXCEPTION 'O dono nao pode sair da Familia' USING ERRCODE = 'P0001', HINT = 'owner_role';
  END IF;
  DELETE FROM family_members WHERE family_id = p_family AND user_id = auth.uid();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Voce nao participa desta Familia' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Permissoes de execucao
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  fn TEXT;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'public.get_my_family_context()',
    'public.create_family(text, text)',
    'public.delete_family(uuid)',
    'public.invite_family_member(uuid, text, public.family_role)',
    'public.list_my_family_invites()',
    'public.accept_family_invite(uuid, text)',
    'public.decline_family_invite(uuid)',
    'public.revoke_family_invite(uuid)',
    'public.change_family_member_role(uuid, uuid, public.family_role)',
    'public.remove_family_member(uuid, uuid)',
    'public.leave_family(uuid)'
  ] LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role', fn);
  END LOOP;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user_profile() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Realtime (respeita RLS): alteracoes de um membro chegam aos demais.
-- ---------------------------------------------------------------------------

ALTER PUBLICATION supabase_realtime ADD TABLE
  public.agenda_items,
  public.agenda_groups,
  public.family_children,
  public.family_members,
  public.families;

-- ---------------------------------------------------------------------------
-- Storage: anexos em user/<uid>/... (pessoal) ou family/<family_id>/... (familia)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can manage own attachments" ON storage.objects;

CREATE POLICY attachments_bucket_select ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'attachments' AND (
      ((storage.foldername(name))[1] = 'user' AND (storage.foldername(name))[2] = auth.uid()::text)
      OR ((storage.foldername(name))[1] = 'family'
          AND private.is_family_member(((storage.foldername(name))[2])::uuid))
    )
  );

CREATE POLICY attachments_bucket_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'attachments' AND (
      ((storage.foldername(name))[1] = 'user' AND (storage.foldername(name))[2] = auth.uid()::text
        AND private.user_has_active_pro(auth.uid()))
      OR ((storage.foldername(name))[1] = 'family'
          AND private.can_edit_family_agenda(((storage.foldername(name))[2])::uuid))
    )
  );

CREATE POLICY attachments_bucket_delete ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'attachments' AND (
      ((storage.foldername(name))[1] = 'user' AND (storage.foldername(name))[2] = auth.uid()::text)
      OR ((storage.foldername(name))[1] = 'family'
          AND private.can_edit_family_agenda(((storage.foldername(name))[2])::uuid))
    )
  );
