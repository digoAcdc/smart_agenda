-- Assinaturas so podem ser gravadas pela billing-api (service_role), depois
-- de validar com o Google. RLS ja bloqueia escrita do app, mas TRUNCATE
-- ignora RLS: tira de vez os privilegios de escrita de anon/authenticated.

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.user_subscriptions, public.purchase_validations, public.premium_allowlist
  FROM anon, authenticated;

REVOKE ALL ON public.user_subscriptions, public.purchase_validations, public.premium_allowlist
  FROM anon;
