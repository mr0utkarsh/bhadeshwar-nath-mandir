// config.example.js → copy to config.js and fill in your Supabase project values.
// The Supabase URL and anon key are PUBLIC by design (protected by RLS policies).
// NEVER put the service_role key here — it is only for scripts/.env (server-side).
window.__CFG = window.__CFG || {};
window.__CFG.supabaseUrl = "";      // https://<project-ref>.supabase.co
window.__CFG.supabaseAnonKey = "";  // Project → API → anon public key
window.__CFG.siteUrl = "https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/"; // canonical URL
