-- Convite por link (WhatsApp) - Fase 2 do roadmap.
-- O convite por link e um family_invites sem e-mail, com um codigo (token).
-- Vale para 1 pessoa, por 7 dias, e ocupa vaga como o convite por e-mail.

ALTER TABLE public.family_invites ALTER COLUMN email DROP NOT NULL;
ALTER TABLE public.family_invites ADD COLUMN IF NOT EXISTS token TEXT UNIQUE;
ALTER TABLE public.family_invites DROP CONSTRAINT IF EXISTS family_invites_email_or_token;
ALTER TABLE public.family_invites ADD CONSTRAINT family_invites_email_or_token
  CHECK (email IS NOT NULL OR token IS NOT NULL);

-- Admin cria o link. Devolve o codigo (vai na URL rbarbosa.tech/convite/<codigo>).
CREATE OR REPLACE FUNCTION public.create_family_invite_link(
  p_family UUID,
  p_role public.family_role DEFAULT 'editor'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_max INTEGER;
  v_used INTEGER;
  v_token TEXT;
BEGIN
  IF NOT private.can_admin_family(p_family) THEN
    RAISE EXCEPTION 'Somente administradores de uma Familia ativa podem convidar' USING ERRCODE = '42501';
  END IF;
  IF p_role = 'admin' THEN
    RAISE EXCEPTION 'Convite por link e para editor ou visualizador' USING ERRCODE = '22023';
  END IF;

  SELECT max_members INTO v_max FROM families WHERE id = p_family FOR UPDATE;
  UPDATE family_invites SET status = 'revoked', responded_at = now()
  WHERE family_id = p_family AND status = 'pending' AND expires_at <= now();
  SELECT (SELECT count(*) FROM family_members WHERE family_id = p_family)
       + (SELECT count(*) FROM family_invites WHERE family_id = p_family AND status = 'pending')
  INTO v_used;
  IF v_used >= v_max THEN
    RAISE EXCEPTION 'Limite de % pessoas na Familia atingido', v_max USING ERRCODE = 'P0001', HINT = 'member_limit';
  END IF;

  -- 12 caracteres sem ambiguidade (sem 0/O, 1/l/I).
  SELECT string_agg(substr('abcdefghjkmnpqrstuvwxyz23456789', (get_byte(b, i) % 31) + 1, 1), '')
    INTO v_token
    FROM (SELECT gen_random_bytes(12) AS b) r, generate_series(0, 11) i;

  INSERT INTO family_invites (family_id, email, token, role, invited_by)
  VALUES (p_family, NULL, v_token, p_role, auth.uid());
  RETURN v_token;
END;
$$;

-- Dados do convite para a tela "aceitar" e a pagina web. Publico (anon), mas
-- so devolve o nome da Familia, quem convidou, o papel e se ainda vale.
CREATE OR REPLACE FUNCTION public.get_family_invite_by_token(p_token TEXT)
RETURNS TABLE (
  family_name TEXT,
  invited_by_name TEXT,
  role public.family_role,
  is_valid BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT f.name,
         COALESCE(NULLIF(m.nickname, ''), NULLIF(p.display_name, ''),
                  split_part(u.email, '@', 1)),
         i.role,
         i.status = 'pending' AND i.expires_at > now() AND private.family_is_active(f.id)
  FROM family_invites i
  JOIN families f ON f.id = i.family_id
  LEFT JOIN family_members m ON m.family_id = i.family_id AND m.user_id = i.invited_by
  LEFT JOIN profiles p ON p.id = i.invited_by
  LEFT JOIN auth.users u ON u.id = i.invited_by
  WHERE i.token = p_token AND length(p_token) BETWEEN 8 AND 64;
$$;

CREATE OR REPLACE FUNCTION public.accept_family_invite_by_token(
  p_token TEXT,
  p_nickname TEXT DEFAULT NULL
)
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
  SELECT * INTO v_inv FROM family_invites WHERE token = p_token FOR UPDATE;
  IF NOT FOUND THEN
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
  UPDATE family_invites SET status = 'accepted', responded_at = now() WHERE id = v_inv.id;
  RETURN v_inv.family_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_family_invite_link(UUID, public.family_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_family_invite_link(UUID, public.family_role) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_family_invite_by_token(TEXT) TO anon, authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.accept_family_invite_by_token(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_family_invite_by_token(TEXT, TEXT) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
