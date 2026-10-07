#!/usr/bin/env node
/**
 * Bulk photo uploader — बाबा भदेश्वर नाथ मंदिर
 *
 * Usage:
 *   1) Put .env next to package.json:  SUPABASE_URL=...  SUPABASE_SERVICE_KEY=...
 *   2) node scripts/upload-photos.js ./photos --category=mela --caption="महाशिवरात्रि मेला"
 *
 * - Optimizes images (sharp, if installed: max 1600px, JPEG q0.82)
 * - Uploads to Supabase Storage bucket "temple-photos" under photos/
 * - Inserts approved rows into public.photos
 *
 * The service_role key is SERVER-ONLY. Never copy it into config.js or the frontend.
 */
const fs = require('fs');
const path = require('path');

// ---- load .env ----
function loadEnv(file) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
}
loadEnv(path.join(__dirname, '..', '.env'));

const URL_ = process.env.SUPABASE_URL;
const KEY = process.env.SUPABASE_SERVICE_KEY;
if (!URL_ || !KEY) {
  console.error('ERROR: SUPABASE_URL / SUPABASE_SERVICE_KEY missing. Create .env from .env.example (server-side only).');
  process.exit(1);
}

// ---- args ----
const argv = process.argv.slice(2);
const folder = argv[0] || './photos';
const opt = (name, dflt) => {
  const i = argv.indexOf('--' + name + '=');
  return i > -1 ? argv[i].split('=').slice(1).join('=') : (argv.includes('--' + name) ? true : dflt);
};
const category = opt('category', 'anya');
const caption = opt('caption', '') || '';
const alt = opt('alt', '') || '';
const captionEn = opt('caption-en', '') || '';

let sharp = null;
try { sharp = require('sharp'); } catch (e) { console.log('sharp not found — uploading originals (run: npm i -D sharp for auto-optimization)'); }

const REST = URL_.replace(/\/$/, '');
const headers = { apikey: KEY, Authorization: 'Bearer ' + KEY };

async function main() {
  const files = fs.readdirSync(folder).filter(f => /\.(jpe?g|png|webp|heic)$/i.test(f));
  if (!files.length) { console.log('No image files in ' + folder); return; }
  console.log(`Uploading ${files.length} photo(s) from ${folder} → temple-photos/photos/ (category=${category})`);
  let ok = 0, fail = 0;
  for (const f of files) {
    const abs = path.join(folder, f);
    const ext = (f.split('.').pop() || 'jpg').toLowerCase().replace(/[^a-z0-9]/g, '') || 'jpg';
    const stored = `photos/${Date.now()}-${Math.random().toString(36).slice(2, 8)}-${f.replace(/[^a-z0-9._-]/gi, '_')}`;
    try {
      let body = fs.readFileSync(abs);
      let mime = 'image/' + (ext === 'jpg' ? 'jpeg' : ext);
      if (sharp) {
        const buf = await sharp(body).resize({ width: 1600, withoutEnlargement: true }).jpeg({ quality: 82 }).toBuffer();
        if (buf.length < body.length) { body = buf; mime = 'image/jpeg'; }
      }
      const up = await fetch(`${REST}/storage/v1/object/temple-photos/${encodeURIComponent(stored)}`, {
        method: 'POST', headers: { ...headers, 'Content-Type': mime, 'x-upsert': 'false' },
        body,
      });
      if (!up.ok) throw new Error(`storage ${up.status}: ${(await up.text()).slice(0, 200)}`);
      const pub = `${REST}/storage/v1/object/public/temple-photos/${encodeURIComponent(stored)}`;
      const captionHi = caption || path.parse(f).name;
      const row = {
        storage_path: stored, caption_hi: captionHi, caption_en: captionEn,
        alt_text: alt || captionHi, category, status: 'approved',
      };
      const ins = await fetch(`${REST}/rest/v1/photos`, {
        method: 'POST', headers: { ...headers, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
        body: JSON.stringify(row),
      });
      if (!ins.ok) throw new Error(`db ${ins.status}: ${(await ins.text()).slice(0, 200)}`);
      ok++;
      console.log(`  ✓ ${f} → ${pub}`);
    } catch (e) {
      fail++;
      console.error(`  ✗ ${f}: ${e.message}`);
    }
  }
  console.log(`Done. ${ok} uploaded, ${fail} failed.`);
}
main();
