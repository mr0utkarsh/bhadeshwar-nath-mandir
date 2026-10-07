# बाबा भदेश्वर नाथ मंदिर, बस्ती | Baba Bhadeshwar Nath Mandir, Basti

**Live:** https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/
**Repo:** https://github.com/mr0utkarsh/bhadeshwar-nath-mandir

हिंदी-first, production-ready मंदिर वेबसाइट — static hosting (GitHub Pages) + Supabase backend (gallery, community posts, sankalp, announcements, live-darshan links) + ब्राउज़र-एनिमेशन (scroll reveal, parallax, equalizer) + भक्ति संगीत प्लेयर।

## फ़ीचर्स / Features

- मंदिर इतिहास (लोकमान्यता स्पष्ट रूप से चिह्नित; अमर उजाला की कथाएँ भी जोड़ी गईं), गायत्री मंत्र (9+महामृत्युंजय, हर मंत्र पर **"▶ सुनें"** — ब्राउज़र TTS, कोई API key नहीं), संस्कृत श्लोक
- **चित्र दीर्घा: 37 असली फोटो** (28 मंदिर/शिवलिंग/मेला + 9 क्षेत्र) — स्रोत: जनपद बस्ती पोर्टल, Google Maps उपयोगकर्ता फोटो (12), MyAdhyatm (8), अमर उजाला (5), Wikimedia Commons CC (9)। श्रेणी फ़िल्टर: मंदिर/आरती/श्रृंगार/मेला/परिसर/**क्षेत्र**; **कोई भी बिना लॉगिन फोटो भेज सकता है — तुरंत सार्वजनिक** (captcha + 30s rate limit)
- **भक्ति संगीत**: 7 CC/Public-Domain भजन MP3 (शिव नाम है जीवन हमारा ×6, शिव आरती) — Internet Archive से, लाइसेंस स्पष्ट; यूट्यूब एम्बेड (Om Namah Shivaya 108×, Mahamrityunjaya, Shiv Tandav, Om Jai Shiv Omkara, Om Tryambakam, प्लेलिस्ट)
- **प्रोफेशनल एनिमेशन**: scroll-reveal, hero parallax, floating diyas/petals, animated counters, navbar shrink, back-to-top, audio equalizer, जाप counter pop
- **Google Maps** embed + "Google Maps पर मार्ग" + Plus Code (QP4R+JG9) + यात्रा जानकारी
- **लाइव दर्शन/आरती** लिंक (समिति द्वारा प्रबंधित), **आधिकारिक घोषणाएँ**
- भक्त मंच: पोस्ट, फोटो सबमिशन, टिप्पणी, 🙏 लाइक, डिजिटल संकल्प — सब moderated
- जाप काउंटर, दैनिक श्लोक, घंटी (WebAudio), मंदिर सहायक (FAQ + आवाज़ से पूछें), खोज, हिंदी/English, dark/light थीम
- PWA (manifest + service worker cache v5), responsive mobile design, Open Graph + JSON-LD + sitemap.xml + robots.txt

## Local setup

```powershell
git clone https://github.com/mr0utkarsh/bhadeshwar-nath-mandir.git
cd bhadeshwar-nath-mandir
npx serve .   # या कोई भी static server
```

`config.js` में Supabase URL + publishable key भरे हैं। अगर Supabase प्रोजेक्ट अभी बना नहीं है (DNS resolve न हो), साइट अपने-आप **डेमो मोड** में चलती है (पोस्ट/फोटो सिर्फ आपके ब्राउज़र में)।

## Supabase setup (एक बार, ~10 मिनट)

1. **प्रोजेक्ट बनाएँ/चेक करें** — https://supabase.com/dashboard/projects। दिया गया प्रोजेक्ट `bsxljzchkrrlwqphpkfu` अगर DNS से resolve न हो तो प्रोजेक्ट अभी active नहीं है — नया बनाएँ या dashboard से status देखें।
2. **SQL schema चलाएँ** — *SQL Editor* → *New query* → `supabase/schema.sql` की पूरी सामग्री पेस्ट करें → *Run*।
   इससे तालिकाएँ (`photos`, `community_posts`, `comments`, `sankalp`, `announcements`, `live_streams`, `admins`), RLS policies और 37 seed फोटो + घोषणा बनती हैं।
3. **Storage bucket** — *Storage* → *Buckets* → *Create bucket*:
   - नाम: `temple-photos`, **Public bucket: ON**
   - फिर `supabase/storage-policies.sql` चलाएँ (storage RLS policies)।
   - Public uploads `submissions/` में जाती हैं; committee uploads `photos/` में।
4. **कनेक्ट करें** — *Project Settings → API* से **Project URL** और **publishable/anon** key लेकर `config.js` भरें (सिर्फ ये दो — **service/secret key कभी frontend में न डालें**):
   ```js
   window.__CFG.supabaseUrl = "https://<project-ref>.supabase.co";
   window.__CFG.supabaseAnonKey = "<publishable key>";
   ```
5. **एडमिन उपयोगकर्ता बनाएँ** — *Authentication → Users → Add user* (email + password)। फिर SQL Editor में:
   ```sql
   insert into public.admins (user_id) values ('<उस user का uuid>');
   ```
6. **Deploy करें**:
   ```powershell
   git add -f config.js; git commit -m "connect supabase"; git push
   ```

## API keys — कैसे इस्तेमाल करें (PowerShell)

> ⚠️ **चेतावनी:** चैट में पेस्ट की गई `SUPABASE_SECRET_KEY` और DB पासवर्ड **rotate कर दें** (Supabase Dashboard → Authentication → API Keys → Rotate; Database → Reset password)। कोई भी secret कभी GitHub पर commit न करें।

सत्र के लिए (PowerShell):
```powershell
$env:GEMINI_API_KEY = "..."      # सिर्फ इस PowerShell सत्र में
```
स्थायी (user scope):
```powershell
setx GEMINI_API_KEY "..."        # नई PowerShell विंडो में effective
```
AI keys (Gemini/Groq/OpenRouter/DeepSeek/11Labs) **बैकेंड प्रॉक्सी के पीछे** ही इस्तेमाल करें — सीधे frontend JS में डालने पर कोई भी विज़िटर उन्हें चुरा लेगा। इस साइट में AI की ज़रूरत नहीं: मंत्र "सुनें" ब्राउज़र `speechSynthesis` से, सहायक local FAQ से, घंटी WebAudio से बनती है।

सर्वर-साइड स्क्रिप्ट्स (जैसे `scripts/upload-photos.js`) `.env` (gitignored) से keys पढ़ती हैं:
```powershell
cp .env.example .env   # फिर .env में SUPABASE_SECRET_KEY वाले keys भरें
```

## फोटो सोर्सिंग (37 असली फोटो — कैसे लाई गईं)

Google Images सीधे auto-scraping ब्लॉक होता है (429) और Bing results में unrelated फोटो (Himachal का Chandra Taal) आती हैं — गलत फोटो न लगाने के नियम के कारण उन्हें नहीं लिया गया। **इस छोटे मंदिर की 50 असली फोटो इंटरनेट पर मौजूद ही नहीं हैं**; वर्तमान में सभी verifiable स्रोतों से 37 जुटाई गई हैं। 50+ तक पहुँचने का रास्ता: भक्त अपनी असली फोटो "फोटो भेजें" फ़ॉर्म से भेजें (तुरंत सार्वजनिक)।

| फोटो | सोर्स | लाइसेंस/नोट |
|---|---|---|
| `assets/temple-official.jpg` | जनपद बस्ती सरकारी पोर्टल (basti.nic.in) — अधिकृत | सरकारी पोर्टल |
| `assets/google-maps-1..12.jpg` | Google Maps उपयोगकर्ता फोटो (इसी स्थान की, inmap24 से) | Google Maps |
| `assets/temple-myadhyatm-1..8.jpg` | MyAdhyatm — इसी मंदिर/शिवलिंग पर लिखे article की gallery | 250×250 (छोटी) |
| `assets/temple-amarujala-1..5.jpg` | अमर उजाला फोटो गैलरी (2018/2021) | अमर उजाला (credit) |
| `assets/temple-festival.jpg`, `temple-aarti.jpg` | जिला पोर्टल gallery | जनपद बस्ती |
| `assets/region-*.jpg` (9) | Wikimedia Commons — बस्ती रेलवे, NH-28, अमोरहा के मंदिर, 1930 का ऐतिहासिक दृश्य | CC0 / CC BY-SA / Public Domain |

**और फोटो कैसे जोड़ें:**
1. असली फोटो डाउनलोड करके repo में `assets/` में रखें।
2. Bulk अपलोड + auto-optimize (1600px, JPEG q0.82):
   ```powershell
   cp .env.example .env          # SUPABASE_SECRET_KEY भरें (server-side only!)
   node scripts/upload-photos.js ./photos --category=mela --caption="महाशिवरात्रि मेला"
   ```
3. या सीधे साइट के "फोटो भेजें" फ़ॉर्म से (कोई लॉगिन नहीं) या admin.html से drag-drop।

केवल अपनी या अनुमति-प्राप्त फोटो अपलोड करें। Duplicate / low-quality / unrelated फोटो न डालें।

## भक्ति संगीत — लाइसेंस

`assets/audio/` के सभी MP3 Internet Archive (archive.org) से, स्पष्ट लाइसेंस:
- `bhajan-shivnam-1..6.mp3` — "शिव नाम है जीवन हमारा", महंत राजेश कुमार तिवारी — **Public Domain Mark 1.0**
- `bhajan-shiv-aarti.mp3` — "शिव आरती" — **CC BY-NC 4.0** (उद्धृति: archive.org item `20260420_20260420_1940`)
- यूट्यूब एम्बेड में कोई फ़ाइल होस्ट नहीं होती — कॉपीराइट यूट्यूब/कलाकार के पास।

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
```powershell
gh api -X POST /repos/mr0utkarsh/bhadeshwar-nath-mandir/pages -f "source[branch]=main" -f "source[path]=/"
# Live: https://mr0utkarsh.github.io/bhadeshwar-nath-mandir/
```

वैकल्पिक: **Cloudflare Pages** या **Vercel** — repo connect करें, build command खाली, output directory `/` — सब free है (उनका अपना free subdomain मिलता है: `*.pages.dev` / `*.vercel.app`)।

### Free / custom domain कैसे लगाएँ (एक बार signup ज़रूरी — डोमेन रजिस्ट्री खाते के बिना कोई डोमेन नहीं मिल सकता)

1. **सबसे आसान (free)**: Cloudflare Pages / Vercel पर repo connect करें → मिलता है `bhadeshwar-nath-mandir.pages.dev` जैसा free subdomain → DNS सेटिंग्स में GitHub Pages को CNAME flatten करें।
2. **Free DNS provider**: `is-a.dev`, `ddns.net`, `cu.cc` आदि free subdomain देते हैं ( signup + A record `185.199.108.153` etc. GitHub Pages IPs)।
3. **अस्थायी (free) domain**: कुछ registrars (Freenom मरा है; .tk/ Dot TK अब paid) — free domain के offers बदलते रहते हैं, सावधानी से verify करें।
4. **Custom domain खरीदना** (.com/.in ~₹100–800/वर्ष): खरीदने के बाद repo में `CNAME` फ़ाइल बनाएँ (उसमें सिर्फ domain नाम), DNS में GitHub Pages A records (`185.199.108.153`, `.154`, `.155`, `.156`) या CNAME `mr0utkarsh.github.io` → push → Settings → Pages → Custom domain। **पहले मंदिर समिति की approval लें।**

> मैं खाता/पेमेंट के बिना कोई डोमेन register नहीं कर सकता — ऊपर के स्टेप आपके signup से 5 मिनट में पूरे होंगे।

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
4. **Supabase project activation** — दिया गया project ref अभी DNS से resolve नहीं हो रहा; dashboard से verify करें या नया बनाएँ।
5. **Google Search Console verification** — आपके Google account से property add करनी होगी।
6. **50+ असली फोटो** — इंटरनेट पर इस मंदिर की 50 फोटो मौजूद नहीं हैं; भक्तों के uploads से बढ़ेंगी।

## Security notes

- frontend में सिर्फ public URL + publishable key (RLS-protected); कोई secret code में hardcode नहीं।
- service_role/secret key सिर्फ `.env` (gitignored) में, सिर्फ `scripts/upload-photos.js` सर्वर-साइड।
- सार्वजनिक users सिर्फ **approved** content देखते हैं (RLS policies)।
- Public photo submissions `approved` तुरंत (captcha + rate-limit के साथ); अनुचित फोटो समिति हटा सकती है।
- AI API keys चैट में साझा हो चुकी हैं — **rotate करें**; प्रॉक्सी के बिना frontend में न डालें।

## Sources

- District Basti portal: https://basti.nic.in/tourist-place/bhadeshwer-nath/ — अधिकृत फोटो + NH-28 + गोरखपुर 80 किमी
- MyAdhyatm: https://myadhyatm.com/bhadeshwar-nath-mandir-kakraeebasti/ — मंदिर/शिवलिंग गैलरी (8 फोटो) + झारकेश्वर बाबा / 1728 की मान्यताएँ
- अमर उजाला: https://www.amarujala.com/photo-gallery/gorakhpur/sawan-2022-special-story-of-baba-bhadeshwar-nath-temple-in-basti — 5 असली फोटो + रावण/युधिष्ठिर/ब्रिटिश कब्ज़े/सरयू जल की कथाएँ
- inmap24: https://inmap24.com/hindu-temple/uttar-pradesh/441973 — Google Maps उपयोगकर्ता फोटो (12) + Plus Code QP4R+JG9
- Wikimedia Commons: बस्ती रेलवे स्टेशन (CC0), NH-28 (CC BY-SA 3.0), अमोरहा मंदिर (CC BY-SA 4.0), 1930 का बस्ती (Public Domain)
- Internet Archive: CC0 / Public Domain / CC BY-NC भजन MP3
- रावण/पांडव/झारकेश्वर/बढ़ता-शिवलिंग/ब्रिटिश-कब्ज़ा कथाएँ लोकमान्यता हैं, प्रमाणित इतिहास नहीं।

**Developer:** [Utkarsh Giri](https://mr0utkarsh.github.io/portfolio-/) — [GitHub](https://github.com/mr0utkarsh)
