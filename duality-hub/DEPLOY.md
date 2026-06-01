# Checklist de despliegue · DUALITY Hub

## 0. Seguridad previa (IMPORTANTE)

El export de Lovable traía un `.env` commiteado con claves reales. **Rota esas claves**
antes de nada: en el proyecto Supabase antiguo o directamente creando uno nuevo. No
reutilices ninguna clave que haya estado en el repositorio público.

## 1. Supabase (backend externo propio)

- [ ] Crear proyecto nuevo en supabase.com y anotar **Project URL**, **anon/publishable key** y **service_role** (esta última solo para ti, nunca al front).
- [ ] SQL Editor → ejecutar `supabase/schema.sql`.
- [ ] SQL Editor → ejecutar `supabase/spa-additions.sql`.
- [ ] Comprobar en **Storage** que existen los buckets: `hero-media`, `artist-images`, `background-images`, `background-videos`, `shop-products`, `gallery`, `authorization-pdfs`, `general-assets`.
- [ ] **Authentication → Providers**: dejar Email activado. Desactivar "Confirm email" si quieres entrar sin verificación (o configurar SMTP).
- [ ] Crear el usuario admin (Authentication → Users → Add user).

## 2. GitHub

- [ ] `git init && git add . && git commit -m "DUALITY Hub: rebuild Vite + Supabase"`.
- [ ] Crear repo nuevo y `git push`. Verificar que `.env` / `.env.local` **no** se suben (ya están en `.gitignore`).

## 3. Vercel

- [ ] Import Project desde GitHub. Framework: **Vite** (autodetectado). Build: `npm run build`. Output: `dist`.
- [ ] Environment Variables (Production + Preview):
  - `VITE_SUPABASE_URL`
  - `VITE_SUPABASE_PUBLISHABLE_KEY`
- [ ] Deploy.
- [ ] Probar `/` (landing) y `/admin` (debe pedir login; tras login, panel).

## 4. Primer acceso admin

- [ ] Ir a `/login`, entrar con el usuario creado. El primer login reclama el rol `admin` automáticamente vía `claim_first_admin()` (solo si no hay ningún admin todavía).

## 5. QA funcional

- [ ] Secciones ON/OFF y reordenado (drag & drop) se reflejan en la landing.
- [ ] Subida de imágenes/PDF/vídeo a cada bucket desde el admin.
- [ ] Favoritos (corazón) en artistas y horarios → Mi Planning (parrilla) persiste en localStorage.
- [ ] Tiquetera visual edita tramos y el CTA redirige al enlace oficial.
- [ ] Carga rápida de artistas y horarios por texto.

## Notas

- Es un SPA: el render es en cliente. Para SEO básico, los meta tags están en `index.html`.
  Si más adelante necesitas SEO fuerte en la landing, se puede añadir prerender.
- La RLS permite lectura pública (`USING (true)`) de todas las tablas de contenido; es
  contenido de marketing público. La escritura está restringida a `has_role(auth.uid(),'admin')`.
