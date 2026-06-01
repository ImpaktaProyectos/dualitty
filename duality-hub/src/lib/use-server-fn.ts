// En la versión SSR de Lovable, las "server functions" se invocaban con
// useServerFn() de TanStack Start. En este SPA ya son funciones cliente
// normales, así que este hook es la identidad y permite reutilizar los
// componentes sin tocar su cuerpo.
export function useServerFn<T>(fn: T): T {
  return fn;
}
