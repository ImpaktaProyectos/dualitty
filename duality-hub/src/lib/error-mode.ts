// Modo "error 404" de la home.
// Se guarda como una fila especial de page_sections (section_key = "error_404"),
// así reutiliza la lectura pública y la escritura de admin que ya existen,
// sin necesidad de tocar el esquema de la base de datos.
// La landing no tiene renderer para esta clave, así que nunca se pinta como sección.

export const ERROR_MODE_KEY = "error_404";

type SectionLike = { section_key: string; is_enabled?: boolean | null };

export function getErrorModeRow<T extends SectionLike>(sections: T[] | null | undefined): T | undefined {
  return (sections ?? []).find((s) => s.section_key === ERROR_MODE_KEY);
}

export function isErrorModeOn(sections: SectionLike[] | null | undefined): boolean {
  return !!getErrorModeRow(sections)?.is_enabled;
}

export function withoutErrorMode<T extends SectionLike>(sections: T[] | null | undefined): T[] {
  return (sections ?? []).filter((s) => s.section_key !== ERROR_MODE_KEY);
}
