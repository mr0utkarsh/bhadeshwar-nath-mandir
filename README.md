# बाबा भदेश्वर नाथ मंदिर, बस्ती | Baba Bhadeshwar Nath Mandir, Basti

**Live:** https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/
**Repo:** https://github.com/mr0utkarsh/bhadeshwar-nath-mandir

हिंदी-first, production-ready मंदिर वेबसाइट — static hosting (GitHub Pages) + Supabase backend (gallery, community posts, sankalp, announcements, live-darshan links)।

## फ़ीचर्स / Features

- मंदिर इतिहास (लोकमान्यता स्पष्ट रूप से चिह्नित), गायत्री मंत्र (9+महामृत्युंजय), संस्कृत श्लोक
- **चित्र दीर्घा**: 13 असली मंदिर/शिवलिंग फोटो (जनपद बस्ती सरकारी पोर्टल, Google Maps उपयोगकर्ता फोटो, MyAdhyatm) + श्रेणी फ़िल्टर (मंदिर/आरती/श्रृंगार/मेला/परिसर); **कोई भी बिना लॉगिन फोटो भेज सकता है — तुरंत सार्वजनिक** (captcha + 30s rate limit; मंदिर समिति हटा सकती है)
- **Google Maps** embed + "Google Maps पर मार्ग" + Plus Code (QP4R+JG9) + यात्रा जानकारी
- **लाइव दर्शन/आरती** लिंक (समिति द्वारा प्रबंधित), **आधिकारिक घोषणाएँ**
- भक्त मंच: पोस्ट, फोटो सबमिशन, टिप्पणी, 🙏 लाइक, डिजिटल संकल्प — सब moderated
- जाप काउंटर, दैनिक श्लोक, घंटी, मंदिर सहायक (FAQ), खोज, हिंदी/English, dark/light थीम
- PWA (manifest + service worker), responsive mobile design, Open Graph + JSON-LD + sitemap.xml + robots.txt

## Local setup

```bash
git clone https://github.com/mr0utkarsh/bhadeshwar-nath-mandir.git
cd bhadeshwar-nath-mandir
cp config.example.js config.js   # फिर config.js भरें (नीचे स्टेप 4)
npx serve .                       # या कोई भी static server
```

अभी भी `config.js` खाली है → साइट **डेमो मोड** में चलती है (पोस्ट/फोटो सिर्फ आपके ब्राउज़र में)।

## Supabase setup (एक बार, ~10 मिनट)

1. **प्रोजेक्ट बनाएँ** — https://supabase.com/dashboard/projects → *New project* (free plan)।
2. **SQL schema चलाएँ** — *SQL Editor* → *New query* → `supabase/schema.sql` की पूरी सामग्री पेस्ट करें → *Run*।
   इससे तालिकाएँ (`photos`, `community_posts`, `comments`, `sankalp`, `announcements`, `live_streams`, `admins`), RLS policies और seed फोटो/घोषणा बनती हैं।
3. **Storage bucket** — *Storage* → *Buckets* → *Create bucket*:
   - नाम: `temple-photos`, **Public bucket: ON**
   - फिर `supabase/storage-policies.sql` चलाएँ (storage RLS policies)।
   - Public uploads `submissions/` में जाती हैं (moderation के लिए); committee uploads `photos/` में।
4. **कनेक्ट करें** — *Project Settings → API* से **Project URL** और **anon public** key लेकर `config.js` भरें:
   ```js
   window.__CFG.supabaseUrl = "https://<project-ref>.supabase.co";
   window.__CFG.supabaseAnonKey = "<anon public key>";
   ```
   > anon key सार्वजनिक करना सुरक्षित है — RLS policies ही सुरक्षा करती हैं। **service_role key कभी भी frontend में न डालें** (वह सिर्फ `scripts/.env` के लिए है)।
5. **Email auth चालू** — *Authentication → Providers → Email* → चालू (default)।
6. **एडमिन उपयोगकर्ता बनाएँ** — *Authentication → Users → Add user* (email + password, email confirm की ज़रूरत नहीं)। फिर SQL Editor में:
   ```sql
   insert into public.admins (user_id) values ('<उस user का uuid>');
   ```
7. **Deploy करें** (नीचे) — `config.js` को commit करना होगा क्योंकि GitHub Pages में env vars नहीं होतीं:
   ```bash
   git add -f config.js && git commit -m "connect supabase" && git push
   ```

## फोटो सोर्सिंग (क्या कैसे लाया गया)

Google Images से सीधे auto-scraping ब्लॉक होता है (429) और Bing results में ज़्यादातर Himachal के **Chandra Taal** की unrelated फोटो आती हैं — गलत (unrelated) फोटो न लगाने के नियम के कारण उन्हें नहीं लिया गया। जो लगाया गया, सब **इसी मंदिर की verified फोटो** है:

| फोटो | सोर्स | रिज़ॉल्यूशन |
|---|---|---|
| `assets/temple-official.jpg` | जनपद बस्ती सरकारी पोर्टल (basti.nic.in) — अधिकृत | 480×359 |
| `assets/google-maps-1..4.jpg` | Google Maps उपयोगकर्ता फोटो (इसी स्थान की, alt-verified) | high-res |
| `assets/temple-myadhyatm-1..6.jpg` | MyAdhyatm — इसी मंदिर/शिवलिंग पर लिखे article की gallery | 250×250 (छोटी) |
| `assets/temple-festival.jpg`, `temple-aarti.jpg` | पहले से मौजूद (Justdial / जिला पोर्टल) | 960×720 / 480×359 |

**और फोटो कैसे जोड़ें (Google Photos / Drive / Dropbox से):**
1. असली शेयर लिंक से फोटो डाउनलोड करके `photos/` फ़ोल्डर में रखें (gitignored)।
2. Bulk अपलोड + auto-optimize (1600px, JPEG q0.82):
   ```bash
   cp .env.example .env          # SUPABASE_URL और SUPABASE_SERVICE_KEY भरें (server-side only!)
   node scripts/upload-photos.js ./photos --category=mela --caption="महाशिवरात्रि मेला"
   ```
3. या सीधे साइट के "फोटो भेजें" फ़ॉर्म से (कोई लॉगिन नहीं) या admin.html से drag-drop।

केवल अपनी या अनुमति-प्राप्त फोटो अपलोड करें। Duplicate / low-quality / unrelated फोटो न डालें।
आस-पास की जगहों (चंदो ताल, वन चेतना केंद्र आदि) की फोटो Google पर easily verifiable नहीं मिलीं, इसलिए Nearby सेक्शन में Google फोटो links दिए गए हैं — असली फोटो मिलने पर ऊपर की तरह जोड़ें।

## Admin instructions (admin.html)

- URL: `https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/admin.html`
- उसी ईमेल/पासवर्ड से लॉगिन जो `admins` तालिका में है।
- **फोटो अपलोड**: सीधे स्वीकृत, सार्वजनिक दीर्घा में तुरंत दिखेगी।
- **फोटो**: कोई भी बिना लॉगिन भेज सकता है, तुरंत सार्वजनिक होती है — अनुचित फोटो "स्वीकृत फोटो" सूची से हटाएँ (Storage + DB दोनों से)।
- **मॉडरेशन**: भक्तों की पोस्ट/टिप्पणी/संकल्प "प्रतीक्षा में" आते हैं → स्वीकृत / अस्वीकार / हटाएँ।
- **घोषणाएँ**: शीर्षक, विवरण, वैधता अवधि, प्राथमिकता। स्वीकृत घोषणा साइट के टॉप बार में दिखती है।
- **लाइव लिंक**: YouTube/Facebook live URL + "सक्रिय" टॉगल — साइट के लाइव सेक्शन में दिखेगा।

## Deployment (free)

**GitHub Pages (चालू, project site):**
```bash
gh repo create bhadeshwar-nath-mandir --public --source=. --remote=origin --push
gh api -X POST /repos/mr0utkarsh/bhadeshwar-nath-mandir/pages \
  -f source[branch]=main -f source[path]=/
# Live: https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/
```

वैकल्पिक (अगर GitHub छोड़ना हो): **Cloudflare Pages** या **Vercel** — repo connect करें, build command खाली, output directory `/` — सब free है।

> Custom domain खरीदने से पहले मंदिर समिति की approval लें। अभी कोई paid domain नहीं लिया गया है।

## SEO / Google Search Console checklist

- [x] Hindi-first content, target keywords in title/meta ("Bhadeshwar Nath Mandir", "Baba Bhadeshwar Nath Mandir Basti", "भदेश्वर नाथ मंदिर", "बाबा भदेश्वर नाथ मंदिर बस्ती")
- [x] canonical URL, OG tags, Twitter card, JSON-LD (HinduTemple), sitemap.xml, robots.txt
- [ ] **Google Search Console**: https://search.google.com/search-console → *Add property* → URL-prefix property `https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/` → **HTML file** verification (वह `google*.html` file repo में commit करें) या DNS/HTML tag method
- [ ] Sitemap submit: GSC → *Sitemaps* → `sitemap.xml` submit
- [ ] *URL Inspection* से homepage + key pages का indexing request करें
- [ ] **कोई ranking या instant-indexing guarantee नहीं** — Google अपने अनुसार crawl करता है; अच्छी content + backlinks (जिला पोर्टल से लिंक आदि) से ranking समय में बढ़ती है
- [ ] **Google Maps profile / Google Business Profile claim करने से पहले मंदिर समिति की official authorization लें** — गलत ownership claim न करें

## Approval / official access के बिना नहीं हो सकता

1. **Google Business Profile (Maps listing) create/claim** — official temple representative की authorization चाहिए।
2. **सटीक मंदिर पिन / पार्किंग / दर्शन-आरती समय** — समिति से सत्यापित होने पर अपडेट।
3. **Custom domain खरीदना** — पहले approval ज़रूरी।
4. **Supabase project creation** — आपके Supabase account से खुद बनाना होगा (credentials साझा नहीं किए गए)।
5. **Google Search Console verification** — आपके Google account से property add करनी होगी।
6. **असली फोटो batch** — Google Search लिंक से auto-डाउनलोड नहीं; असली शेयर लिंक/फ़ाइलें चाहिए।

## Security notes

- कोई secret code में hardcode नहीं: frontend सिर्फ public URL + anon key (RLS-protected)।
- service_role key सिर्फ `.env` (gitignored) में, सिर्फ `scripts/upload-photos.js` सर्वर-साइड।
- सार्वजनिक users सिर्फ **approved** content देखते हैं (RLS policies)।
- Public submissions `pending` में रहती हैं जब तक committee approve न करे।

## Sources

- District Basti portal: https://basti.nic.in/tourist-place/bhadeshwer-nath/ (हिंदी: /hi/tourist-place/भादेश्वर-नाथ/) — अधिकृत फोटो + NH-28 + गोरखपुर 80 किमी
- MyAdhyatm: https://myadhyatm.com/bhadeshwar-nath-mandir-kakraeebasti/ — मंदिर/शिवलिंग गैलरी (6 फोटो) + झारकेश्वर बाबा / 1728 की मान्यताएँ
- inmap24: https://inmap24.com/hindu-temple/uttar-pradesh/441973 — Google Maps उपयोगकर्ता फोटो (4) + Plus Code QP4R+JG9
- रावण/पांडव/झारकेश्वर/बढ़ता-शिवलिंग कथाएँ लोकमान्यता हैं, प्रमाणित इतिहास नहीं।
- Bundled photos: `assets/temple-festival.jpg` (Justdial listing), `assets/temple-aarti.jpg` (District Basti gallery)

**Developer:** [Utkarsh Giri](https://mr0utkarsh.github.io/portfolio-/) — [GitHub](https://github.com/mr0utkarsh)
