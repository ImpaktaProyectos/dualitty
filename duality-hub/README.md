# DUALITY Hub

Web de evento único para **DUALITY** (fiestas de música electrónica) con landing pública y panel de administración. Reconstrucción limpia, **sin Lovable Cloud**, lista para **Vercel + Supabase externo propio**.

- **Stack:** Vite + React 19 + TypeScript + Tailwind 4 + shadcn/ui.
- **Routing:** React Router (`/` landing, `/login`, `/admin` protegida).
- **Datos/auth/storage:** Supabase (cliente anon + RLS). Sin SSR, sin service_role en el front.
- **Despliegue:** Vercel (estático). GitHub como repo.

## Qué cambió respecto al export de Lovable

- Se eliminó **TanStack Start + SSR**, el target **Cloudflare Workers** (`wrangler`, `@cloudflare/vite-plugin`, `server.ts`, `start.ts`) y el wrapper propietario `@lovable.dev/vite-tanstack-config`.
- Las **server functions** (que usaban la `service_role` y se saltaban la RLS) se reescribieron como **funciones de cliente** con firmas idénticas (`src/lib/site.functions.ts`, `src/lib/admin.functions.ts`). La seguridad ahora la aplica la **RLS** (lectura pública + escritura admin via `has_role`).
- `claimFirstAdmin` pasó a una función SQL `SECURITY DEFINER` (`claim_first_admin`).
- Toda la UI (secciones, editores admin, drag&drop, favoritos, Mi Planning en localStorage) se **reutiliza intacta**.

## Puesta en marcha (local)

```bash
npm install
cp .env.example .env.local   # rellena con TU proyecto Supabase
npm run dev                  # http://localhost:5173
```

### Variables de entorno (`.env.local`)

Solo claves públicas (se incrustan en el bundle). **Nunca** pongas la `service_role` aquí.

```
VITE_SUPABASE_URL="https://TU-PROYECTO.supabase.co"
VITE_SUPABASE_PUBLISHABLE_KEY="tu-anon-publishable-key"
```

## Base de datos (Supabase)

En tu proyecto Supabase nuevo, SQL Editor:

1. Ejecuta `supabase/schema.sql` (14 tablas, RLS, triggers, buckets, seeds).
2. Ejecuta `supabase/spa-additions.sql` (buckets `gallery`, `authorization-pdfs`, `general-assets` + función `claim_first_admin`).

### Primer admin

1. Crea un usuario en **Authentication → Users** (o regístrate con ese email).
2. Inicia sesión en `/login`. El primer login ejecuta `claim_first_admin()`, que te asigna el rol `admin` **solo si aún no existe ninguno**.
3. A partir de ahí gestiona roles desde `user_roles`.

## Despliegue en Vercel

1. Sube el repo a GitHub e impórtalo en Vercel (framework detectado: **Vite**).
2. En **Settings → Environment Variables** añade `VITE_SUPABASE_URL` y `VITE_SUPABASE_PUBLISHABLE_KEY`.
3. Deploy. El `vercel.json` ya reescribe todas las rutas a `index.html` (necesario para `/admin` y rutas internas del SPA).

Ver `DEPLOY.md` para el checklist completo.

## Estructura

```
src/
  pages/        Landing.tsx · Login.tsx · Admin.tsx · NotFound.tsx
  components/   secciones públicas, admin/ (editores), ui/ (shadcn)
  lib/          site.functions.ts · admin.functions.ts · auth.tsx · use-server-fn.ts
  integrations/supabase/  client.ts (anon) · types.ts
  hooks/        useFavorites.ts (localStorage) · use-mobile.tsx
supabase/       schema.sql · spa-additions.sql
```
