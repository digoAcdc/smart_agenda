-- Remove o modelo antigo de compartilhamento (agenda pessoal lida por terceiros)
-- e fecha brechas encontradas no banco antes do modelo de Familia (017).
-- Projeto em desenvolvimento: as tabelas de agenda sao recriadas em 017.

-- Policy criada manualmente no banco (fora das migrations): leitura publica de agenda_items.
DROP POLICY IF EXISTS "allow_read_agenda_items" ON public.agenda_items;

-- Compartilhamento antigo (sem convite/aceite, somente leitura da agenda pessoal).
DROP TABLE IF EXISTS public.agenda_shares CASCADE;

-- Permitia descobrir se um e-mail tem conta no app.
DROP FUNCTION IF EXISTS public.get_user_id_by_email(text);

-- Tabelas de agenda recriadas com escopo pessoal/familia em 017.
DROP TABLE IF EXISTS public.attachments CASCADE;
DROP TABLE IF EXISTS public.agenda_items CASCADE;
DROP TABLE IF EXISTS public.agenda_groups CASCADE;

-- Funcoes de push expunham tokens FCM para anon/authenticated.
-- O n8n chama com service_role, que continua com acesso.
DO $$
DECLARE
  fn regprocedure;
BEGIN
  FOR fn IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'get_premium_users_%'
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', fn);
  END LOOP;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_subscription_premium_status() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_subscription_premium_status() TO authenticated, service_role;
