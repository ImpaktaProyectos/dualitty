-- ============================================================
-- DUALITY HUB · Añadidos para la versión SPA (Vite + Vercel)
-- Ejecutar DESPUÉS de schema.sql.
-- ============================================================

-- 1) Buckets que el código usa/espera pero que las migraciones no creaban
--    (sus políticas de storage ya existen en schema.sql: "duality buckets *").
INSERT INTO storage.buckets (id, name, public) VALUES
  ('gallery', 'gallery', true),
  ('authorization-pdfs', 'authorization-pdfs', true),
  ('general-assets', 'general-assets', true)
ON CONFLICT (id) DO NOTHING;

-- 2) Reclamar admin la primera vez de forma segura.
--    Sustituye a la server function claimFirstAdmin(). SECURITY DEFINER porque
--    un usuario autenticado NO puede insertarse a sí mismo en user_roles via RLS.
--    Solo concede admin si todavía no existe ningún admin.
CREATE OR REPLACE FUNCTION public.claim_first_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_count INT;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM public.user_roles WHERE role = 'admin';
  IF admin_count > 0 THEN
    RETURN FALSE;
  END IF;
  INSERT INTO public.user_roles (user_id, role)
  VALUES (auth.uid(), 'admin')
  ON CONFLICT DO NOTHING;
  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_first_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_first_admin() TO authenticated;

-- 3) Endurecer: claim_first_admin solo para usuarios autenticados (no anon)
REVOKE EXECUTE ON FUNCTION public.claim_first_admin() FROM anon;
