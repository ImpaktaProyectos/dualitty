import { useEffect, useState } from "react";

// Pantalla de "error 404 / mantenimiento" que sustituye a TODA la home cuando
// el modo error está activo desde el panel (Admin → interruptor "Modo error 404").
// Solo muestra esto: sin menú, sin secciones, sin enlaces.

const STEPS = [
  "Detectando el fallo…",
  "Analizando servidores…",
  "Arreglando el fallo…",
  "Reconectando la experiencia…",
  "Cargando…",
];

type Props = {
  settings?: {
    primary_color?: string | null;
    secondary_color?: string | null;
    event_name?: string | null;
    brand_logo_light_url?: string | null;
    brand_logo_main_url?: string | null;
  } | null;
};

export function ErrorScreen({ settings }: Props) {
  const [progress, setProgress] = useState(0);
  const [cycle, setCycle] = useState(0);

  // Colores de marca del evento + título de pestaña + noindex mientras esté activa
  useEffect(() => {
    const root = document.documentElement;
    if (settings?.primary_color) root.style.setProperty("--brand-blue", settings.primary_color);
    if (settings?.secondary_color) root.style.setProperty("--brand-red", settings.secondary_color);
    const prevTitle = document.title;
    document.title = `404 · ${settings?.event_name ?? "DUALITY"}`;
    const meta = document.createElement("meta");
    meta.name = "robots";
    meta.content = "noindex";
    document.head.appendChild(meta);
    return () => {
      document.title = prevTitle;
      meta.remove();
    };
  }, [settings]);

  // Progreso "realista": avanza rápido al principio, se frena cerca del final,
  // llega a 100 %, y vuelve a empezar (reintento).
  useEffect(() => {
    const id = setInterval(() => {
      setProgress((p) => {
        if (p >= 100) return 100;
        const remaining = 100 - p;
        const stepUp = p < 70 ? 1.6 + Math.random() * 2.4 : Math.max(0.15, remaining * 0.04 * Math.random());
        return Math.min(100, p + stepUp);
      });
    }, 140);
    return () => clearInterval(id);
  }, [cycle]);

  useEffect(() => {
    if (progress < 100) return;
    const t = setTimeout(() => {
      setProgress(0);
      setCycle((c) => c + 1);
    }, 1400);
    return () => clearTimeout(t);
  }, [progress]);

  const stepIndex = progress >= 100 ? STEPS.length - 1 : Math.min(STEPS.length - 2, Math.floor((progress / 100) * (STEPS.length - 1)));
  const label = progress >= 100 ? "Reintentando conexión…" : STEPS[stepIndex];
  const logo = settings?.brand_logo_light_url || settings?.brand_logo_main_url;

  return (
    <div className="err404 relative min-h-[100svh] w-full overflow-hidden bg-[var(--dark-bg)] text-white flex items-center justify-center px-5">
      {/* Luces de fondo (azul / rojo — la dualidad) */}
      <div aria-hidden className="err404-glow err404-glow-blue" />
      <div aria-hidden className="err404-glow err404-glow-red" />
      <div aria-hidden className="err404-scan" />
      <div aria-hidden className="absolute inset-0 grain pointer-events-none" />

      <main className="relative z-10 w-full max-w-xl text-center">
        {/* Marca */}
        <div className="mb-10 flex justify-center">
          {logo ? (
            <img src={logo} alt={settings?.event_name ?? "DUALITY"} className="h-7 md:h-8 object-contain opacity-90" />
          ) : (
            <span className="text-display text-lg md:text-xl font-black tracking-[0.35em]">
              DUA<span style={{ color: "var(--brand-red)" }}>L</span>
              <span style={{ color: "var(--brand-blue)" }}>I</span>TY
            </span>
          )}
        </div>

        <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-[10px] md:text-[11px] uppercase tracking-[0.35em] text-white/60">
          <span className="err404-dot" /> Error del sistema
        </div>

        {/* 404 con efecto glitch azul/rojo */}
        <h1 className="err404-title text-display font-black leading-none mt-6" data-text="404">
          404
        </h1>

        <p className="text-display mt-4 text-xl md:text-2xl font-bold uppercase tracking-[0.18em]">
          Algo ha fallado
        </p>
        <p className="mt-3 text-sm md:text-base text-white/55 max-w-sm mx-auto">
          Estamos trabajando para solucionarlo. Vuelve en unos minutos.
        </p>

        {/* Barra de progreso */}
        <div className="mt-10 text-left" role="status" aria-live="polite">
          <div className="flex items-end justify-between mb-2 text-[11px] md:text-xs uppercase tracking-[0.25em]">
            <span className="text-white/70">{label}</span>
            <span className="tabular-nums text-[var(--brand-blue)] font-bold">{Math.floor(progress)}%</span>
          </div>
          <div
            className="relative h-2 w-full overflow-hidden rounded-full bg-white/[0.06] border border-white/10"
            role="progressbar"
            aria-valuemin={0}
            aria-valuemax={100}
            aria-valuenow={Math.floor(progress)}
          >
            <div className="err404-bar absolute inset-y-0 left-0 rounded-full" style={{ width: `${progress}%` }} />
          </div>
          <div className="mt-3 flex justify-between text-[10px] uppercase tracking-[0.3em] text-white/30">
            <span>Código 404</span>
            <span>Intento #{cycle + 1}</span>
          </div>
        </div>
      </main>

      <style>{`
        .err404-glow { position:absolute; width:70vmax; height:70vmax; border-radius:9999px; filter:blur(90px); opacity:.28; pointer-events:none; }
        .err404-glow-blue { background: var(--brand-blue); top:-35vmax; left:-25vmax; animation: err404-float 14s ease-in-out infinite; }
        .err404-glow-red  { background: var(--brand-red);  bottom:-40vmax; right:-28vmax; opacity:.2; animation: err404-float 18s ease-in-out infinite reverse; }
        @keyframes err404-float { 0%,100% { transform: translate3d(0,0,0) scale(1); } 50% { transform: translate3d(4vmax,3vmax,0) scale(1.08); } }

        .err404-scan { position:absolute; inset:0; pointer-events:none;
          background: repeating-linear-gradient(0deg, transparent 0 3px, rgba(255,255,255,0.025) 3px 4px); mix-blend-mode: overlay; }

        .err404-dot { width:6px; height:6px; border-radius:9999px; background: var(--brand-red);
          box-shadow: 0 0 10px var(--brand-red); animation: err404-blink 1.1s steps(2,end) infinite; }
        @keyframes err404-blink { 50% { opacity:.2; } }

        .err404-title { position:relative; font-size: clamp(7rem, 28vw, 13rem); letter-spacing:-0.04em; color:#fff;
          text-shadow: 0 0 40px var(--blue-glow); }
        .err404-title::before, .err404-title::after { content: attr(data-text); position:absolute; inset:0; mix-blend-mode: screen; }
        .err404-title::before { color: var(--brand-blue); animation: err404-glitch-a 3.2s infinite steps(1,end); }
        .err404-title::after  { color: var(--brand-red);  animation: err404-glitch-b 3.2s infinite steps(1,end); }
        @keyframes err404-glitch-a {
          0%,86%,100% { transform: translate(-3px,0); clip-path: inset(0 0 0 0); opacity:.75; }
          88% { transform: translate(-10px,-2px); clip-path: inset(10% 0 55% 0); }
          91% { transform: translate(8px,2px);  clip-path: inset(60% 0 8% 0); }
          94% { transform: translate(-5px,0);  clip-path: inset(35% 0 35% 0); }
        }
        @keyframes err404-glitch-b {
          0%,86%,100% { transform: translate(3px,0); clip-path: inset(0 0 0 0); opacity:.6; }
          88% { transform: translate(10px,2px); clip-path: inset(55% 0 12% 0); }
          91% { transform: translate(-8px,-2px); clip-path: inset(5% 0 70% 0); }
          94% { transform: translate(5px,0); clip-path: inset(40% 0 30% 0); }
        }

        .err404-bar { background: linear-gradient(90deg, var(--brand-blue), color-mix(in oklab, var(--brand-blue) 50%, var(--brand-red)), var(--brand-red));
          box-shadow: 0 0 18px var(--blue-glow), 0 0 28px var(--red-glow); transition: width .14s linear; }
        .err404-bar::after { content:""; position:absolute; inset:0; border-radius:inherit;
          background: linear-gradient(90deg, transparent, rgba(255,255,255,.55), transparent); background-size: 50% 100%;
          background-repeat:no-repeat; animation: err404-shine 1.4s linear infinite; }
        @keyframes err404-shine { from { background-position: -60% 0; } to { background-position: 160% 0; } }

        @media (prefers-reduced-motion: reduce) {
          .err404-glow, .err404-title::before, .err404-title::after, .err404-bar::after, .err404-dot { animation: none !important; }
        }
      `}</style>
    </div>
  );
}
