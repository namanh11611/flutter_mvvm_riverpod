// VS Code's built-in TypeScript service does not know Supabase Edge Function
// (Deno) globals or `npm:` imports. These declarations keep editor diagnostics
// useful when the Deno extension is not installed; Deno ignores this file at
// runtime.

declare module "npm:@supabase/supabase-js@2" {
  export type SupabaseClient = any;
  export const createClient: (...args: any[]) => SupabaseClient;
}

declare const Deno: {
  serve(
    handler: (request: Request) => Response | Promise<Response>,
  ): void;
  env: {
    get(name: string): string | undefined;
  };
};
