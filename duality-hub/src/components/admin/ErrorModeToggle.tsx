import { useState } from "react";
import { toast } from "sonner";
import { AlertTriangle, Eye } from "lucide-react";
import { upsertRow } from "@/lib/admin.functions";
import { ERROR_MODE_KEY, getErrorModeRow } from "@/lib/error-mode";

type Row = { id?: string; section_key: string; section_name?: string; is_enabled?: boolean | null; [k: string]: unknown };

// Interruptor de un clic para mostrar la pantalla "Error 404" en la home.
// Con el modo activo, los visitantes SOLO ven el 404 con la barra de progreso.
export function ErrorModeToggle({ sections, onSaved }: { sections: Row[]; onSaved: () => void }) {
  const row = getErrorModeRow(sections);
  const on = !!row?.is_enabled;
  const [busy, setBusy] = useState(false);

  const setMode = async (next: boolean) => {
    setBusy(true);
    try {
      const values: Record<string, unknown> = row
        ? { ...row, is_enabled: next }
        : {
            section_key: ERROR_MODE_KEY,
            section_name: "Modo error 404",
            is_enabled: next,
            display_mode: "hidden",
            sort_order: 999,
            admin_status: "complete",
          };
      await upsertRow({ data: { table: "page_sections", values } });
      onSaved();
      if (next) {
        toast.error("Modo 404 ACTIVADO · la home solo muestra el error", {
          action: { label: "Deshacer", onClick: () => setMode(false) },
        });
      } else {
        toast.success("Modo 404 desactivado · la web vuelve a estar visible");
      }
    } catch (e: any) {
      toast.error(e.message ?? "No se pudo cambiar el modo 404");
    } finally {
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      disabled={busy}
      onClick={() => setMode(!on)}
      title={on ? "La home muestra el error 404. Pulsa para desactivar." : "Pulsa para mostrar el error 404 en la home."}
      className={`inline-flex items-center gap-2 rounded-full border px-2 py-1 md:pl-3 md:pr-1.5 md:py-1 text-[11px] md:text-xs uppercase tracking-widest font-bold transition-all disabled:opacity-60 ${
        on
          ? "border-[var(--brand-red)] bg-[var(--brand-red)]/15 text-white shadow-[0_0_22px_var(--red-glow)]"
          : "border-white/10 text-white/70 hover:text-white hover:border-white/30"
      }`}
    >
      <span className="hidden sm:inline">Modo 404</span>
      <span className="sm:hidden">404</span>
      <span
        className={`relative inline-block h-5 w-9 rounded-full transition-colors ${on ? "bg-[var(--brand-red)]" : "bg-white/15"}`}
      >
        <span
          className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-all ${on ? "left-[18px]" : "left-0.5"}`}
        />
      </span>
    </button>
  );
}

// Aviso bajo la cabecera mientras el modo 404 está activo.
export function ErrorModeBanner({ sections }: { sections: Row[] }) {
  if (!getErrorModeRow(sections)?.is_enabled) return null;
  return (
    <div className="border-t border-[var(--brand-red)]/40 bg-[var(--brand-red)]/15">
      <div className="max-w-7xl mx-auto px-3 md:px-8 py-2 flex flex-wrap items-center justify-between gap-2 text-xs">
        <span className="inline-flex items-center gap-2 text-white">
          <AlertTriangle className="h-4 w-4 text-[var(--brand-red)]" />
          <strong className="uppercase tracking-widest">Modo 404 activo</strong>
          <span className="text-white/70 hidden md:inline">· Los visitantes solo ven la pantalla de error.</span>
        </span>
        <a
          href="/?preview"
          target="_blank"
          className="inline-flex items-center gap-1 uppercase tracking-widest text-white/80 hover:text-white"
        >
          <Eye className="h-3.5 w-3.5" /> Ver la web real (solo tú)
        </a>
      </div>
    </div>
  );
}
