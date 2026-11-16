import { createClient } from "npm:@supabase/supabase-js@2.119.0";
import { createHandler } from "./handler.ts";
import { PairingService } from "./service.ts";

const url = Deno.env.get("SUPABASE_URL");
const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!url || !key) throw new Error("Supabase server configuration is missing");
const client = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});
Deno.serve(createHandler(new PairingService(client)));
