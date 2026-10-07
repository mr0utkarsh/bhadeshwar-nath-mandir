// Loads the Supabase client if config.js provides URL + anon key.
// Falls back to null (demo/offline mode) so the site still works before setup.
(function () {
  var cfg = window.__CFG || {};
  if (cfg.supabaseUrl && cfg.supabaseAnonKey && window.supabase && window.supabase.createClient) {
    try {
      window.__sb = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
    } catch (e) {
      window.__sb = null;
    }
  } else {
    window.__sb = null;
  }
})();
