import { supabase } from "@/integrations/supabase/client";

// Lectura pública de la landing. Antes corría en servidor con service_role;
// ahora va con la clave anon y la RLS "public read" de cada tabla.
// Filtramos is_visible en cliente, igual que hacía la server function.
export async function getLandingData() {
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
    supabase.from("site_settings").select("*").limit(1).maybeSingle(),
    supabase.from("page_sections").select("*").order("sort_order"),
    supabase.from("quick_info_items").select("*").eq("is_visible", true).order("sort_order"),
    supabase.from("artists").select("*").eq("is_visible", true).order("sort_order"),
    supabase.from("schedule_items").select("*").eq("is_visible", true).order("sort_order"),
    supabase.from("gallery_items").select("*").eq("is_visible", true).order("sort_order"),
    supabase.from("bus_routes").select("*").eq("is_visible", true).order("sort_order"),
    supabase.from("faqs").select("*").eq("is_visible", true).order("sort_order"),
    supabase.from("visual_settings").select("*").limit(1).maybeSingle(),
    supabase.from("section_backgrounds").select("*"),
    supabase.from("stages").select("*").eq("is_visible", true).order("sort_order"),
    supabase
      .from("ticket_tiers")
      .select("*")
      .eq("is_visible", true)
      .neq("status", "hidden")
      .order("sort_order"),
    supabase.from("shop_products").select("*").eq("is_visible", true).order("sort_order"),
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
