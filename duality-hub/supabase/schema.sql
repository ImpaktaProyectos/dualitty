-- ============================================================
-- DUALITY HUB · Esquema completo de Supabase
-- Consolidación de las 14 migraciones originales en orden.
-- Ejecutar en el SQL Editor de tu proyecto Supabase nuevo.
-- Incluye: tablas, RLS (lectura pública + escritura admin via has_role),
-- triggers updated_at, buckets de storage, enum app_role y seeds.
-- ============================================================


-- >>> 20260519200515_642eb843-6d12-4452-b058-5438ebdac10d.sql

CREATE TYPE public.app_role AS ENUM ('admin', 'editor');

CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE POLICY "user_roles self read" ON public.user_roles FOR SELECT TO authenticated
USING (auth.uid() = user_id OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "user_roles admin manage" ON public.user_roles FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE TABLE public.site_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_event_key TEXT NOT NULL DEFAULT 'aqua-open-air-2026',
  event_name TEXT NOT NULL DEFAULT 'AQUA OPEN AIR',
  event_subtitle TEXT DEFAULT 'Summer Edition',
  event_date TEXT DEFAULT 'Sábado 18 julio',
  opening_time TEXT DEFAULT '22:00',
  venue_name TEXT DEFAULT 'KM Cero',
  venue_location TEXT DEFAULT 'Ledaña',
  primary_color TEXT DEFAULT '#00AEEF',
  secondary_color TEXT DEFAULT '#FF1E2D',
  glow_color TEXT DEFAULT 'rgba(0,174,239,0.65)',
  background_color TEXT DEFAULT '#03060B',
  hero_video_desktop_url TEXT,
  hero_video_mobile_url TEXT,
  hero_image_desktop_url TEXT,
  hero_image_mobile_url TEXT,
  hero_title TEXT DEFAULT 'AQUA OPEN AIR',
  hero_subtitle TEXT DEFAULT 'Summer Edition',
  hero_cta_primary_text TEXT DEFAULT 'Comprar entradas',
  hero_cta_primary_url TEXT DEFAULT '#entradas',
  hero_cta_secondary_text TEXT DEFAULT 'Ver artistas',
  hero_cta_secondary_url TEXT DEFAULT '#artistas',
  ticket_iframe_url TEXT,
  ticket_fallback_url TEXT,
  ticket_status TEXT DEFAULT 'available',
  ticket_title TEXT DEFAULT 'Compra tus entradas',
  ticket_text TEXT DEFAULT 'Venta oficial mediante Fourvenues.',
  ticket_trust_text TEXT DEFAULT 'Compra segura · Entrada digital · Acceso oficial',
  ticket_show_fallback BOOLEAN DEFAULT TRUE,
  countdown_enabled BOOLEAN DEFAULT TRUE,
  countdown_datetime TIMESTAMPTZ,
  countdown_title TEXT DEFAULT 'La cuenta atrás ha empezado',
  countdown_subtext TEXT DEFAULT 'Asegura tu entrada antes de que se agoten.',
  countdown_cta_text TEXT DEFAULT 'Comprar ahora',
  countdown_cta_url TEXT DEFAULT '#entradas',
  location_name TEXT DEFAULT 'KM Cero',
  location_address TEXT DEFAULT 'Ledaña, Cuenca',
  location_city TEXT DEFAULT 'Ledaña',
  location_maps_url TEXT DEFAULT 'https://maps.google.com/?q=Ledaña',
  location_embed_url TEXT,
  location_parking_text TEXT DEFAULT 'Parking gratuito en el recinto.',
  location_access_text TEXT DEFAULT 'Acceso peatonal por la entrada principal.',
  location_button_text TEXT DEFAULT 'Cómo llegar',
  authorization_title TEXT DEFAULT 'Autorización para menores',
  authorization_description TEXT DEFAULT 'Descarga, rellena y entrega la autorización en el acceso.',
  authorization_pdf_url TEXT,
  authorization_button_text TEXT DEFAULT 'Descargar PDF',
  final_cta_title TEXT DEFAULT 'Vive tu dualidad',
  final_cta_text TEXT DEFAULT 'Una noche. Dos energías. Un mismo destino.',
  final_cta_button_text TEXT DEFAULT 'Comprar entradas',
  final_cta_button_url TEXT DEFAULT '#entradas',
  final_cta_background_url TEXT,
  footer_logo_url TEXT,
  footer_instagram_url TEXT DEFAULT 'https://instagram.com',
  footer_tiktok_url TEXT DEFAULT 'https://tiktok.com',
  footer_facebook_url TEXT,
  footer_email TEXT DEFAULT 'info@duality.events',
  footer_legal_url TEXT DEFAULT '#',
  footer_privacy_url TEXT DEFAULT '#',
  footer_cookies_url TEXT DEFAULT '#',
  footer_copyright TEXT DEFAULT '© DUALITY Events',
  appearance_preset TEXT DEFAULT 'aqua',
  appearance_glow_intensity INTEGER DEFAULT 65,
  appearance_particles BOOLEAN DEFAULT TRUE,
  appearance_texture BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_singleton BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (is_singleton)
);
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER site_settings_touch BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "site_settings public read" ON public.site_settings FOR SELECT USING (TRUE);
CREATE POLICY "site_settings admin write" ON public.site_settings FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.page_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key TEXT NOT NULL UNIQUE,
  section_name TEXT NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  display_mode TEXT NOT NULL DEFAULT 'visible',
  sort_order INTEGER NOT NULL DEFAULT 0,
  admin_status TEXT NOT NULL DEFAULT 'complete',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.page_sections ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER page_sections_touch BEFORE UPDATE ON public.page_sections FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "page_sections public read" ON public.page_sections FOR SELECT USING (TRUE);
CREATE POLICY "page_sections admin write" ON public.page_sections FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.quick_info_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  value TEXT,
  icon TEXT,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.quick_info_items ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER quick_info_touch BEFORE UPDATE ON public.quick_info_items FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "quick_info public read" ON public.quick_info_items FOR SELECT USING (TRUE);
CREATE POLICY "quick_info admin write" ON public.quick_info_items FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.artists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  image_url TEXT,
  stage TEXT,
  performance_time TEXT,
  instagram_url TEXT,
  music_url TEXT,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.artists ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER artists_touch BEFORE UPDATE ON public.artists FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "artists public read" ON public.artists FOR SELECT USING (TRUE);
CREATE POLICY "artists admin write" ON public.artists FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.schedule_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stage TEXT NOT NULL,
  artist_id UUID REFERENCES public.artists(id) ON DELETE SET NULL,
  custom_artist_name TEXT,
  start_time TEXT,
  end_time TEXT,
  description TEXT,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.schedule_items ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER schedule_touch BEFORE UPDATE ON public.schedule_items FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "schedule public read" ON public.schedule_items FOR SELECT USING (TRUE);
CREATE POLICY "schedule admin write" ON public.schedule_items FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.gallery_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  media_type TEXT NOT NULL DEFAULT 'image',
  title TEXT,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.gallery_items ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER gallery_touch BEFORE UPDATE ON public.gallery_items FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "gallery public read" ON public.gallery_items FOR SELECT USING (TRUE);
CREATE POLICY "gallery admin write" ON public.gallery_items FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.bus_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  town TEXT NOT NULL,
  departure_point TEXT,
  departure_time TEXT,
  return_time TEXT,
  price TEXT,
  booking_url TEXT,
  status TEXT NOT NULL DEFAULT 'available',
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.bus_routes ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER bus_routes_touch BEFORE UPDATE ON public.bus_routes FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "bus_routes public read" ON public.bus_routes FOR SELECT USING (TRUE);
CREATE POLICY "bus_routes admin write" ON public.bus_routes FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER faqs_touch BEFORE UPDATE ON public.faqs FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE POLICY "faqs public read" ON public.faqs FOR SELECT USING (TRUE);
CREATE POLICY "faqs admin write" ON public.faqs FOR ALL TO authenticated
USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

INSERT INTO storage.buckets (id, name, public) VALUES
  ('hero-media', 'hero-media', TRUE),
  ('artist-images', 'artist-images', TRUE),
  ('gallery', 'gallery', TRUE),
  ('authorization-pdfs', 'authorization-pdfs', TRUE),
  ('general-assets', 'general-assets', TRUE)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "duality buckets public read" ON storage.objects FOR SELECT USING (
  bucket_id IN ('hero-media','artist-images','gallery','authorization-pdfs','general-assets')
);
CREATE POLICY "duality buckets admin write" ON storage.objects FOR ALL TO authenticated
USING (
  bucket_id IN ('hero-media','artist-images','gallery','authorization-pdfs','general-assets')
  AND public.has_role(auth.uid(), 'admin')
) WITH CHECK (
  bucket_id IN ('hero-media','artist-images','gallery','authorization-pdfs','general-assets')
  AND public.has_role(auth.uid(), 'admin')
);

INSERT INTO public.site_settings (countdown_datetime) VALUES (now() + INTERVAL '45 days');

INSERT INTO public.page_sections (section_key, section_name, is_enabled, display_mode, sort_order) VALUES
  ('hero','Hero',TRUE,'visible',10),
  ('quick_info','Información rápida',TRUE,'visible',20),
  ('countdown','Cuenta atrás',TRUE,'visible',30),
  ('tickets','Entradas',TRUE,'visible',40),
  ('artists','Artistas',TRUE,'visible',50),
  ('schedule','Horarios',TRUE,'visible',60),
  ('gallery','Galería',TRUE,'visible',70),
  ('location','Ubicación',TRUE,'visible',80),
  ('buses','Buses',FALSE,'hidden',90),
  ('authorization','Autorización',FALSE,'hidden',100),
  ('faq','FAQ',TRUE,'visible',110),
  ('final_cta','CTA final',TRUE,'visible',120),
  ('footer','Footer',TRUE,'visible',130);

INSERT INTO public.quick_info_items (label, sort_order) VALUES
  ('18 JULIO',1),('22:00H',2),('KM CERO LEDAÑA',3),('3 ÁREAS',4),('PISCINA EXTERIOR',5),('FOODTRUCK',6);

INSERT INTO public.artists (name, stage, performance_time, is_featured, sort_order) VALUES
  ('NOVA TWIN','Open Air','02:00', TRUE, 1),
  ('KAIRO','Main Room','01:00', TRUE, 2),
  ('LUNA REIGN','Area Club','03:30', FALSE, 3),
  ('SYREN','Open Air','00:00', FALSE, 4),
  ('VEKTOR','Main Room','04:00', TRUE, 5),
  ('OBSIDIAN','Area Club','05:00', FALSE, 6);

INSERT INTO public.schedule_items (stage, custom_artist_name, start_time, end_time, sort_order) VALUES
  ('Open Air','SYREN','00:00','02:00',1),
  ('Open Air','NOVA TWIN','02:00','04:00',2),
  ('Main Room','KAIRO','01:00','04:00',3),
  ('Main Room','VEKTOR','04:00','06:00',4),
  ('Area Club','LUNA REIGN','03:30','05:00',5),
  ('Area Club','OBSIDIAN','05:00','07:00',6);

INSERT INTO public.faqs (question, answer, sort_order) VALUES
  ('¿Dónde puedo comprar las entradas?','Las entradas oficiales se compran desde esta misma web a través del módulo de Fourvenues.',1),
  ('¿Dónde se celebra el evento?','En KM Cero, Ledaña. Tienes el mapa y el botón "Cómo llegar" en la sección Ubicación.',2),
  ('¿A qué hora empieza?','La apertura de puertas es a las 22:00.',3),
  ('¿Puedo entrar si soy menor de edad?','Solo con autorización firmada por padre/madre/tutor y DNI original.',4),
  ('¿Habrá buses?','Publicaremos las rutas y horarios disponibles en la sección Buses cuando estén confirmadas.',5),
  ('¿Puedo salir y volver a entrar?','Se permite reentrada con sellado de pulsera hasta la hora indicada en el acceso.',6);


-- >>> 20260519200532_32748b64-40d4-4c26-8913-32cd3887b8b5.sql

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

REVOKE EXECUTE ON FUNCTION public.has_role(UUID, public.app_role) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.has_role(UUID, public.app_role) TO service_role;


-- >>> 20260519200550_897cf157-53ba-4f05-9f56-ef29b90ac72c.sql

GRANT EXECUTE ON FUNCTION public.has_role(UUID, public.app_role) TO authenticated;


-- >>> 20260519205733_1505b138-648c-4758-9630-dd8d780321ae.sql
ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS hero_flyer_url text,
  ADD COLUMN IF NOT EXISTS hero_flyer_enabled boolean DEFAULT false;

-- >>> 20260519210122_eee0c406-5c5c-45c2-a73d-bdd1994424e6.sql
-- Tabla singleton de configuración visual global
CREATE TABLE IF NOT EXISTS public.visual_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  is_singleton boolean NOT NULL DEFAULT true UNIQUE,
  background_type text NOT NULL DEFAULT 'solid', -- solid|gradient|image|video|pattern
  background_color text DEFAULT '#03060B',
  background_secondary_color text DEFAULT '#0a1a2e',
  background_image_url text,
  background_video_url text,
  background_position text DEFAULT 'center',
  background_size text DEFAULT 'cover',
  background_repeat boolean DEFAULT false,
  background_fixed boolean DEFAULT false,
  image_opacity integer DEFAULT 60,
  overlay_color text DEFAULT '#000000',
  overlay_opacity integer DEFAULT 55,
  blur_amount integer DEFAULT 0,
  saturation integer DEFAULT 100,
  contrast integer DEFAULT 100,
  glow_intensity text DEFAULT 'medium', -- off|low|medium|high
  texture_type text DEFAULT 'none', -- none|noise|grid|scanlines|vignette|dual-split|radial|light-beams
  texture_opacity integer DEFAULT 25,
  motion_type text DEFAULT 'none', -- none|particles|pulse-glow|gradient-shift|light-sweep
  motion_enabled boolean DEFAULT false,
  motion_speed text DEFAULT 'medium', -- slow|medium|fast
  atmosphere_preset text DEFAULT 'aqua',
  readability_mode text DEFAULT 'medium', -- low|medium|high
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.visual_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "visual_settings public read" ON public.visual_settings FOR SELECT USING (true);
CREATE POLICY "visual_settings admin write" ON public.visual_settings FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE TRIGGER visual_settings_touch BEFORE UPDATE ON public.visual_settings
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

INSERT INTO public.visual_settings (is_singleton) VALUES (true) ON CONFLICT DO NOTHING;

-- Tabla de fondos por sección
CREATE TABLE IF NOT EXISTS public.section_backgrounds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  use_global_background boolean NOT NULL DEFAULT true,
  background_type text DEFAULT 'solid',
  background_color text,
  background_secondary_color text,
  background_image_url text,
  background_video_url text,
  background_position text DEFAULT 'center',
  background_size text DEFAULT 'cover',
  image_opacity integer DEFAULT 60,
  overlay_color text DEFAULT '#000000',
  overlay_opacity integer DEFAULT 55,
  blur_amount integer DEFAULT 0,
  texture_type text DEFAULT 'none',
  texture_opacity integer DEFAULT 25,
  motion_type text DEFAULT 'none',
  motion_enabled boolean DEFAULT false,
  motion_speed text DEFAULT 'medium',
  glow_intensity text DEFAULT 'medium',
  readability_mode text DEFAULT 'medium',
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.section_backgrounds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "section_backgrounds public read" ON public.section_backgrounds FOR SELECT USING (true);
CREATE POLICY "section_backgrounds admin write" ON public.section_backgrounds FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));

CREATE TRIGGER section_backgrounds_touch BEFORE UPDATE ON public.section_backgrounds
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Seed por sección
INSERT INTO public.section_backgrounds (section_key) VALUES
  ('hero'),('quick_info'),('countdown'),('tickets'),('artists'),('schedule'),
  ('gallery'),('location'),('buses'),('authorization'),('faq'),('final_cta'),('footer')
ON CONFLICT (section_key) DO NOTHING;

-- Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES
  ('background-images','background-images', true),
  ('background-videos','background-videos', true),
  ('textures','textures', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies (públicas lectura, admin escritura)
CREATE POLICY "bg images public read" ON storage.objects FOR SELECT
  USING (bucket_id IN ('background-images','background-videos','textures'));

CREATE POLICY "bg images admin write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('background-images','background-videos','textures') AND has_role(auth.uid(),'admin'));

CREATE POLICY "bg images admin update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id IN ('background-images','background-videos','textures') AND has_role(auth.uid(),'admin'));

CREATE POLICY "bg images admin delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id IN ('background-images','background-videos','textures') AND has_role(auth.uid(),'admin'));

-- >>> 20260519211822_5fe71a6d-2025-42a0-9be3-4dabdea49cf8.sql
ALTER TABLE public.visual_settings
  ADD COLUMN IF NOT EXISTS background_scroll_mode text NOT NULL DEFAULT 'continuous';

-- >>> 20260520051451_b61d608c-2114-4e62-98d9-b6322fe11aaa.sql

ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS header_logo_url text,
  ADD COLUMN IF NOT EXISTS header_logo_height integer DEFAULT 36,
  ADD COLUMN IF NOT EXISTS font_display text DEFAULT 'Space Grotesk',
  ADD COLUMN IF NOT EXISTS font_body text DEFAULT 'Inter',
  ADD COLUMN IF NOT EXISTS footer_twitter_url text,
  ADD COLUMN IF NOT EXISTS footer_youtube_url text,
  ADD COLUMN IF NOT EXISTS footer_spotify_url text,
  ADD COLUMN IF NOT EXISTS footer_soundcloud_url text,
  ADD COLUMN IF NOT EXISTS footer_whatsapp_url text,
  ADD COLUMN IF NOT EXISTS footer_telegram_url text,
  ADD COLUMN IF NOT EXISTS footer_x_url text;


-- >>> 20260520054238_caec6e63-27f1-4912-a30e-9b3dff0382c6.sql
ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS ticket_mode text NOT NULL DEFAULT 'iframe',
  ADD COLUMN IF NOT EXISTS countdown_subtitle text DEFAULT 'Cada segundo te acerca a la noche.',
  ADD COLUMN IF NOT EXISTS font_button text;

ALTER TABLE public.visual_settings
  ADD COLUMN IF NOT EXISTS background_scroll_behavior text NOT NULL DEFAULT 'normal',
  ADD COLUMN IF NOT EXISTS background_scroll_intensity integer NOT NULL DEFAULT 30;

ALTER TABLE public.section_backgrounds
  ADD COLUMN IF NOT EXISTS background_scroll_behavior text DEFAULT 'normal',
  ADD COLUMN IF NOT EXISTS background_scroll_intensity integer DEFAULT 30;

-- >>> 20260520101111_26c0a900-75c7-41ad-89d7-59ee128e0432.sql
-- Phase 1: Stages, branding, sections lock, FK relations

-- 1) stages table
CREATE TABLE IF NOT EXISTS public.stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  color text,
  sort_order integer NOT NULL DEFAULT 0,
  is_visible boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.stages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stages public read" ON public.stages
  FOR SELECT TO public USING (true);

CREATE POLICY "stages admin write" ON public.stages
  FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER stages_touch_updated_at
  BEFORE UPDATE ON public.stages
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 2) Seed default stages
INSERT INTO public.stages (name, slug, color, sort_order) VALUES
  ('Open Air', 'open-air', '#00AEEF', 0),
  ('Main Room', 'main-room', '#FF1E2D', 1),
  ('Area Club', 'area-club', '#A855F7', 2)
ON CONFLICT (slug) DO NOTHING;

-- 3) artists.stage_id
ALTER TABLE public.artists
  ADD COLUMN IF NOT EXISTS stage_id uuid REFERENCES public.stages(id) ON DELETE SET NULL;

-- 4) schedule_items.stage_id
ALTER TABLE public.schedule_items
  ADD COLUMN IF NOT EXISTS stage_id uuid REFERENCES public.stages(id) ON DELETE SET NULL;

-- 5) Backfill stage_id by normalized name match
UPDATE public.artists a
SET stage_id = s.id
FROM public.stages s
WHERE a.stage_id IS NULL
  AND a.stage IS NOT NULL
  AND lower(regexp_replace(trim(a.stage), '\s+', '-', 'g')) = s.slug;

UPDATE public.schedule_items si
SET stage_id = s.id
FROM public.stages s
WHERE si.stage_id IS NULL
  AND si.stage IS NOT NULL
  AND lower(regexp_replace(trim(si.stage), '\s+', '-', 'g')) = s.slug;

-- 6) page_sections.is_locked
ALTER TABLE public.page_sections
  ADD COLUMN IF NOT EXISTS is_locked boolean NOT NULL DEFAULT false;

UPDATE public.page_sections
SET is_locked = true
WHERE section_key IN ('header', 'footer', 'hero');

-- 7) site_settings brand logos
ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS brand_logo_main_url text,
  ADD COLUMN IF NOT EXISTS brand_logo_light_url text,
  ADD COLUMN IF NOT EXISTS brand_logo_dark_url text,
  ADD COLUMN IF NOT EXISTS brand_icon_url text,
  ADD COLUMN IF NOT EXISTS brand_favicon_url text;


-- >>> 20260521091452_59d7699c-55ef-48d0-82b8-76b5853dad65.sql
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS ticket_embed_script text;

-- >>> 20260522063953_f6066f02-0db2-4664-a67e-3ea5947bbecd.sql
-- Create ticket_tiers table
CREATE TABLE IF NOT EXISTS public.ticket_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price text,
  previous_price text,
  currency text DEFAULT '€',
  status text NOT NULL DEFAULT 'available',
  badge_text text,
  button_text text DEFAULT 'Comprar entrada',
  purchase_url text,
  open_in_new_tab boolean NOT NULL DEFAULT true,
  is_featured boolean NOT NULL DEFAULT false,
  is_visible boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ticket_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ticket_tiers public read" ON public.ticket_tiers FOR SELECT USING (true);
CREATE POLICY "ticket_tiers admin write" ON public.ticket_tiers FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER ticket_tiers_touch BEFORE UPDATE ON public.ticket_tiers
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Extend site_settings with visual ticketer fields
ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS ticket_global_url text,
  ADD COLUMN IF NOT EXISTS use_global_ticket_url boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS ticket_alert_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS ticket_alert_text text,
  ADD COLUMN IF NOT EXISTS ticket_alert_type text DEFAULT 'info',
  ADD COLUMN IF NOT EXISTS ticket_alert_url text,
  ADD COLUMN IF NOT EXISTS tier_countdown_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS tier_countdown_datetime timestamptz,
  ADD COLUMN IF NOT EXISTS tier_countdown_text text;

-- >>> 20260522143844_62f24e9b-a9ca-405f-9e61-7cde5cb09e8b.sql
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS gallery_layout text NOT NULL DEFAULT 'grid';

-- >>> 20260522153814_dd6d0da0-ae66-40ba-ab19-b91aa18f848f.sql

-- Shop products table
CREATE TABLE public.shop_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price text,
  image_url text,
  whatsapp_message text,
  button_text text DEFAULT 'Pedir por WhatsApp',
  is_visible boolean NOT NULL DEFAULT true,
  is_featured boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.shop_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shop_products public read" ON public.shop_products
  FOR SELECT TO public USING (true);

CREATE POLICY "shop_products admin write" ON public.shop_products
  FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER shop_products_touch
  BEFORE UPDATE ON public.shop_products
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Add shop config columns to site_settings
ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS shop_title text DEFAULT 'Tienda oficial',
  ADD COLUMN IF NOT EXISTS shop_subtitle text DEFAULT 'Lleva contigo un trozo de la noche.',
  ADD COLUMN IF NOT EXISTS shop_whatsapp_phone text,
  ADD COLUMN IF NOT EXISTS shop_cta_message text DEFAULT 'Hola! Quiero pedir información sobre este producto:',
  ADD COLUMN IF NOT EXISTS shop_fallback_url text,
  ADD COLUMN IF NOT EXISTS shop_fallback_text text DEFAULT 'Contáctanos';

-- Register the new section
INSERT INTO public.page_sections (section_key, section_name, sort_order, is_enabled, display_mode, admin_status, is_locked)
VALUES ('shop', 'Tienda', 12, true, 'visible', 'complete', false)
ON CONFLICT DO NOTHING;

-- Storage bucket for product images
INSERT INTO storage.buckets (id, name, public) VALUES ('shop-products', 'shop-products', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "shop-products public read" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'shop-products');

CREATE POLICY "shop-products admin write" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'shop-products' AND has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "shop-products admin update" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'shop-products' AND has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "shop-products admin delete" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'shop-products' AND has_role(auth.uid(), 'admin'::app_role));


-- >>> 20260522160522_cbf1c084-7d04-4616-8146-ac48f6ded0d4.sql
-- Remove broad SELECT policies on storage.objects to prevent file listing.
-- Public buckets still serve files via public CDN URLs without requiring SELECT on storage.objects.
DROP POLICY IF EXISTS "bg images public read" ON storage.objects;
DROP POLICY IF EXISTS "duality buckets public read" ON storage.objects;
DROP POLICY IF EXISTS "shop-products public read" ON storage.objects;
