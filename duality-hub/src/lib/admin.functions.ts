import { supabase } from "@/integrations/supabase/client";

// Estas funciones sustituyen a las "server functions" de TanStack Start.
// Ahora se ejecutan en el navegador con la sesión del admin; la autorización
// la garantiza la RLS de Supabase: cada tabla tiene "admin write" con
// has_role(auth.uid(),'admin'). Mantenemos la lista blanca de tablas como
// salvaguarda de UX/coherencia.

const ALLOWED_TABLES = [
  "site_settings",
  "page_sections",
  "artists",
  "schedule_items",
  "gallery_items",
  "bus_routes",
  "faqs",
  "quick_info_items",
  "visual_settings",
  "section_backgrounds",
  "stages",
  "ticket_tiers",
  "shop_products",
] as const;
type TableName = (typeof ALLOWED_TABLES)[number];

function assertTable(t: string): asserts t is TableName {
  if (!(ALLOWED_TABLES as readonly string[]).includes(t)) {
    throw new Error(`Tabla no permitida: ${t}`);
  }
}

// Helper sin tipado estricto de tabla (la tabla se valida en runtime).
const db = supabase as unknown as {
  from: (t: string) => any;
  rpc: (fn: string, args?: Record<string, unknown>) => any;
  auth: typeof supabase.auth;
};

export async function getAdminData() {
  const [
    settings,
    sections,
    quickInfo,
    artists,
    schedule,
    gallery,
    buses,
    faqs,
    atmosphere,
    sectionBgs,
    stages,
    ticketTiers,
    shopProducts,
  ] = await Promise.all([
    db.from("site_settings").select("*").limit(1).maybeSingle(),
    db.from("page_sections").select("*").order("sort_order"),
    db.from("quick_info_items").select("*").order("sort_order"),
    db.from("artists").select("*").order("sort_order"),
    db.from("schedule_items").select("*").order("sort_order"),
    db.from("gallery_items").select("*").order("sort_order"),
    db.from("bus_routes").select("*").order("sort_order"),
    db.from("faqs").select("*").order("sort_order"),
    db.from("visual_settings").select("*").limit(1).maybeSingle(),
    db.from("section_backgrounds").select("*").order("section_key"),
    db.from("stages").select("*").order("sort_order"),
    db.from("ticket_tiers").select("*").order("sort_order"),
    db.from("shop_products").select("*").order("sort_order"),
  ]);
  return {
    settings: settings.data,
    sections: sections.data ?? [],
    quickInfo: quickInfo.data ?? [],
    artists: artists.data ?? [],
    schedule: schedule.data ?? [],
    gallery: gallery.data ?? [],
    buses: buses.data ?? [],
    faqs: faqs.data ?? [],
    atmosphere: atmosphere.data,
    sectionBackgrounds: sectionBgs.data ?? [],
    stages: stages.data ?? [],
    ticketTiers: ticketTiers.data ?? [],
    shopProducts: shopProducts.data ?? [],
  };
}

export async function upsertRow({ data: input }: { data: { table: string; values: Record<string, unknown> } }) {
  assertTable(input.table);
  const values: Record<string, unknown> = { ...input.values };
  const isNew = !values.id;
  if (isNew) {
    const defaults: Record<string, Record<string, unknown>> = {
      artists: { name: "Nuevo artista" },
      stages: { name: "Nuevo escenario", slug: `stage-${Date.now()}` },
      shop_products: { name: "Nuevo producto" },
      ticket_tiers: { name: "Nueva entrada" },
      bus_routes: { town: "Nueva ruta" },
      schedule_items: { stage: "main" },
      faqs: { question: "Nueva pregunta", answer: "" },
      gallery_items: { media_url: "" },
    };
    const d = defaults[input.table];
    if (d) for (const k of Object.keys(d)) if (values[k] == null || values[k] === "") values[k] = d[k];
  }
  const { data: row, error } = await db.from(input.table).upsert(values).select().maybeSingle();
  if (error) throw new Error(error.message);
  return row;
}

export async function deleteRow({ data: input }: { data: { table: string; id: string } }) {
  assertTable(input.table);
  // Seguridad: no borrar un escenario con artistas u horarios vinculados.
  if (input.table === "stages") {
    const [{ count: ac }, { count: sc }] = await Promise.all([
      db.from("artists").select("id", { count: "exact", head: true }).eq("stage_id", input.id),
      db.from("schedule_items").select("id", { count: "exact", head: true }).eq("stage_id", input.id),
    ]);
    if ((ac ?? 0) + (sc ?? 0) > 0) {
      throw new Error("No se puede eliminar: hay artistas u horarios vinculados a este escenario.");
    }
  }
  const { error } = await db.from(input.table).delete().eq("id", input.id);
  if (error) throw new Error(error.message);
  return { ok: true };
}

export async function reorderSections({ data: input }: { data: { items: Array<{ id: string; sort_order: number }> } }) {
  const { data: current } = await db.from("page_sections").select("id,is_locked");
  const lockedIds = new Set((current ?? []).filter((r: any) => r.is_locked).map((r: any) => r.id));
  await Promise.all(
    input.items
      .filter((it) => !lockedIds.has(it.id))
      .map((it) => db.from("page_sections").update({ sort_order: it.sort_order }).eq("id", it.id)),
  );
  return { ok: true };
}

function slugify(s: string) {
  return s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function normalizeName(s: string) {
  return s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "")
    .trim();
}

export async function bulkUpsertSchedule({ data: input }: {
  data: {
    items: Array<{
      start_time: string;
      end_time?: string | null;
      artist_name: string;
      stage_name: string;
      sort_order?: number;
    }>;
    options: { createMissingArtists?: boolean; replaceAll?: boolean; updateArtistStageIfEmpty?: boolean };
  };
}) {
  const opts = input.options ?? {};

  const [{ data: stagesRows }, { data: artistsRows }] = await Promise.all([
    db.from("stages").select("id,name,slug"),
    db.from("artists").select("id,name,stage_id"),
  ]);
  const stagesBySlug = new Map<string, any>((stagesRows ?? []).map((s: any) => [s.slug, s]));
  const artistsByLower = new Map<string, any>((artistsRows ?? []).map((a: any) => [normalizeName(a.name), a]));

  // Asegurar escenarios
  for (const it of input.items) {
    const slug = slugify(it.stage_name);
    if (!slug) continue;
    if (!stagesBySlug.has(slug)) {
      const { data: created } = await db
        .from("stages")
        .insert({ name: it.stage_name, slug, sort_order: stagesBySlug.size })
        .select()
        .maybeSingle();
      if (created) stagesBySlug.set(slug, created);
    }
  }

  // Asegurar artistas
  if (opts.createMissingArtists !== false) {
    for (const it of input.items) {
      const key = normalizeName(it.artist_name);
      if (!key) continue;
      if (!artistsByLower.has(key)) {
        const stage = stagesBySlug.get(slugify(it.stage_name));
        const { data: created } = await db
          .from("artists")
          .insert({
            name: it.artist_name,
            stage: it.stage_name,
            stage_id: stage?.id ?? null,
            sort_order: artistsByLower.size,
          })
          .select()
          .maybeSingle();
        if (created) artistsByLower.set(key, created);
      }
    }
  }

  if (opts.replaceAll) {
    await db.from("schedule_items").delete().not("id", "is", null);
  }

  const rows: any[] = [];
  let order = 0;
  for (const it of input.items) {
    const stage = stagesBySlug.get(slugify(it.stage_name));
    const artist = artistsByLower.get(normalizeName(it.artist_name));

    if (opts.updateArtistStageIfEmpty !== false && artist && !artist.stage_id && stage) {
      await db.from("artists").update({ stage_id: stage.id, stage: stage.name }).eq("id", artist.id);
      artist.stage_id = stage.id;
    }

    rows.push({
      artist_id: artist?.id ?? null,
      custom_artist_name: artist ? null : it.artist_name,
      stage: stage?.name ?? it.stage_name,
      stage_id: stage?.id ?? null,
      start_time: it.start_time,
      end_time: it.end_time ?? null,
      sort_order: it.sort_order ?? order,
      is_visible: true,
    });
    order++;
  }

  if (rows.length) {
    const { error } = await db.from("schedule_items").insert(rows);
    if (error) throw new Error(error.message);
  }

  await syncArtistTimesInternal();
  return { ok: true, inserted: rows.length };
}

// Recalcula artists.performance_time a partir de schedule_items.
async function syncArtistTimesInternal() {
  const { data: items } = await db
    .from("schedule_items")
    .select("artist_id,stage_id,start_time,sort_order")
    .order("sort_order");
  if (!items) return;
  const byStage = new Map<string, any[]>();
  for (const it of items) {
    const k = it.stage_id ?? "__none__";
    if (!byStage.has(k)) byStage.set(k, []);
    byStage.get(k)!.push(it);
  }
  const updates: { id: string; performance_time: string }[] = [];
  for (const arr of byStage.values()) {
    arr.sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0));
    for (let i = 0; i < arr.length; i++) {
      const cur = arr[i];
      if (!cur.artist_id || !cur.start_time) continue;
      const next = arr[i + 1];
      const text = next?.start_time ? `${cur.start_time} - ${next.start_time}` : cur.start_time;
      updates.push({ id: cur.artist_id, performance_time: text });
    }
  }
  await Promise.all(
    updates.map((u) => db.from("artists").update({ performance_time: u.performance_time }).eq("id", u.id)),
  );
}

export async function resyncArtistTimes(_arg?: unknown) {
  await syncArtistTimesInternal();
  return { ok: true };
}

// Reclama el rol admin si todavía no existe ninguno. Lógica protegida por la
// función SECURITY DEFINER public.claim_first_admin() (ver supabase/spa-additions.sql),
// porque un usuario normal no puede insertarse a sí mismo en user_roles via RLS.
export async function claimFirstAdmin() {
  const { data, error } = await db.rpc("claim_first_admin");
  if (error) throw new Error(error.message);
  return { claimed: !!data };
}

export async function isCurrentUserAdmin() {
  const { data: auth } = await db.auth.getUser();
  const userId = auth?.user?.id;
  if (!userId) return { isAdmin: false };
  const { data } = await db
    .from("user_roles")
    .select("role")
    .eq("user_id", userId)
    .eq("role", "admin")
    .maybeSingle();
  return { isAdmin: !!data };
}
