-- ============================================================================
-- बाबा भदेश्वर नाथ मंदिर, बस्ती — Supabase schema
-- Run once in SQL Editor: https://supabase.com/dashboard/project/<ref>/sql
-- Creates: admins, photos, community_posts, comments, sankalp, announcements,
--         live_streams + Row Level Security policies + like counter function.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table if not exists public.admins (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  role     text not null default 'admin' check (role in ('admin', 'moderator')),
  created_at timestamptz not null default now()
);

comment on table public.admins is 'Mandir committee members allowed to moderate and upload.';

create table if not exists public.photos (
  id          uuid primary key default gen_random_uuid(),
  storage_path text,                 -- path inside "temple-photos" bucket (admin uploads)
  local_src    text,                 -- bundled asset path e.g. assets/temple-festival.jpg (seed only)
  caption_hi  text not null,
  caption_en  text,
  alt_text    text not null,
  category    text not null check (category in ('mandir','aarti','shringar','mela','paris','anya')),
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null,
  check (coalesce(storage_path, local_src) is not null)
);

create table if not exists public.community_posts (
  id         uuid primary key default gen_random_uuid(),
  name       text,
  category   text not null check (category in ('bhakti','prarthana','shringar','samachar','khoya-paya')),
  body       text not null check (char_length(body) between 1 and 500),
  photo_path text,                   -- submissions/ path from public upload
  status     text not null default 'pending' check (status in ('pending','approved','rejected')),
  likes      int not null default 0 check (likes >= 0),
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null
);

create table if not exists public.comments (
  id        uuid primary key default gen_random_uuid(),
  post_id   uuid not null references public.community_posts(id) on delete cascade,
  name      text,
  body      text not null check (char_length(body) between 1 and 200),
  status    text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.sankalp (
  id        uuid primary key default gen_random_uuid(),
  name      text,
  body      text not null check (char_length(body) between 1 and 140),
  status    text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (char_length(title) between 1 and 120),
  body       text not null check (char_length(body) between 1 and 1000),
  priority   int not null default 0,
  valid_from timestamptz,
  valid_to   timestamptz,
  status     text not null default 'draft' check (status in ('draft','approved','archived')),
  created_at timestamptz not null default now()
);

create table if not exists public.live_streams (
  id        uuid primary key default gen_random_uuid(),
  title     text not null check (char_length(title) between 1 and 120),
  url       text not null check (url ~ '^https?://'),
  platform  text,
  is_active boolean not null default false,
  status    text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security — public users only ever see approved content
-- ---------------------------------------------------------------------------
alter table public.admins          enable row level security;
alter table public.photos          enable row level security;
alter table public.community_posts enable row level security;
alter table public.comments        enable row level security;
alter table public.sankalp         enable row level security;
alter table public.announcements   enable row level security;
alter table public.live_streams    enable row level security;

-- helpers reused in policies
create or replace function public.is_admin() returns boolean
language sql stable security definer as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- admins: any signed-in user may check whether they are on the committee list
create policy "signed-in users may read admin list"
  on public.admins for select
  to authenticated
  using (true);

-- photos
create policy "public sees approved photos"
  on public.photos for select
  to anon, authenticated
  using (status = 'approved');

create policy "anyone may upload a photo (published immediately, no login)"
  on public.photos for insert
  to anon
  with check (status = 'approved' and storage_path like 'submissions/%');

create policy "committee manages all photos"
  on public.photos for all
  to authenticated
  using (public.is_admin())
  with check (true);

-- community posts
create policy "public sees approved posts"
  on public.community_posts for select
  to anon, authenticated
  using (status = 'approved');

create policy "anyone may submit a post for moderation"
  on public.community_posts for insert
  to anon
  with check (status = 'pending'
              and (photo_path is null or photo_path like 'submissions/%'));

create policy "committee manages all posts"
  on public.community_posts for all
  to authenticated
  using (public.is_admin())
  with check (true);

-- comments
create policy "public sees approved comments"
  on public.comments for select
  to anon, authenticated
  using (status = 'approved');

create policy "anyone may submit a comment for moderation"
  on public.comments for insert
  to anon
  with check (status = 'pending');

create policy "committee manages all comments"
  on public.comments for all
  to authenticated
  using (public.is_admin())
  with check (true);

-- sankalp
create policy "public sees approved sankalp"
  on public.sankalp for select
  to anon, authenticated
  using (status = 'approved');

create policy "anyone may submit a sankalp for moderation"
  on public.sankalp for insert
  to anon
  with check (status = 'pending');

create policy "committee manages all sankalp"
  on public.sankalp for all
  to authenticated
  using (public.is_admin())
  with check (true);

-- announcements
create policy "public sees live approved announcements"
  on public.announcements for select
  to anon, authenticated
  using (status = 'approved'
         and (valid_from is null or valid_from <= now())
         and (valid_to   is null or valid_to   >= now()));

create policy "committee manages announcements"
  on public.announcements for all
  to authenticated
  using (public.is_admin())
  with check (true);

-- live streams
create policy "public sees approved active streams"
  on public.live_streams for select
  to anon, authenticated
  using (status = 'approved' and is_active = true);

create policy "committee manages live streams"
  on public.live_streams for all
  to authenticated
  using (public.is_admin())
  with check (true);

-- ---------------------------------------------------------------------------
-- Like counter (definer: only increments approved posts; no RLS bypass risk)
-- ---------------------------------------------------------------------------
create or replace function public.increment_like(p_id uuid) returns void
language sql security definer as $$
  update public.community_posts set likes = likes + 1
  where id = p_id and status = 'approved';
$$;
grant execute on function public.increment_like(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Seed data (bundled real photos already in the repo + first announcement)
-- 37 photos: District Basti portal (basti.nic.in), Google Maps user photos
-- (via inmap24), MyAdhyatm temple article, Amar Ujala photo gallery, and
-- Wikimedia Commons (CC-licensed regional photos). All temple photos are of
-- THIS temple only; region photos are labelled as Basti district / Amorha.
-- ---------------------------------------------------------------------------
insert into public.photos (local_src, caption_hi, caption_en, alt_text, category, status)
values
  ('assets/temple-festival.jpg',
   'शिवधाम श्री बाबा भदेश्वर नाथ मंदिर का प्रवेशद्वार',
   'Gateway of Baba Bhadeshwar Nath Temple',
   'बाबा भदेश्वर नाथ मंदिर, बस्ती का प्रवेशद्वार',
   'mandir', 'approved'),
  ('assets/temple-aarti.jpg',
   'पर्व पर सजा हुआ मंदिर',
   'Temple decorated for the festival',
   'पर्व के समय सजा हुआ बाबा भदेश्वर नाथ मंदिर',
   'aarti', 'approved'),
  ('assets/temple-official.jpg',
   'अधिकृत फोटो: जनपद बस्ती सरकारी पोर्टल',
   'Official photo: District Basti government portal',
   'जनपद बस्ती सरकारी पोर्टल की बाबा भदेश्वर नाथ मंदिर की अधिकृत फोटो',
   'mandir', 'approved'),
  ('assets/google-maps-1.jpg', 'Google Maps उपयोगकर्ता फोटो', 'Google Maps user photo', 'Google Maps पर बाबा भदेश्वर नाथ मंदिर की फोटो 1', 'mandir', 'approved'),
  ('assets/google-maps-2.jpg', 'Google Maps उपयोगकर्ता फोटो', 'Google Maps user photo', 'Google Maps पर बाबा भदेश्वर नाथ मंदिर की फोटो 2', 'mandir', 'approved'),
  ('assets/google-maps-3.jpg', 'Google Maps उपयोगकर्ता फोटो', 'Google Maps user photo', 'Google Maps पर बाबा भदेश्वर नाथ मंदिर की फोटो 3', 'mandir', 'approved'),
  ('assets/google-maps-4.jpg', 'Google Maps उपयोगकर्ता फोटो', 'Google Maps user photo', 'Google Maps पर बाबा भदेश्वर नाथ मंदिर की फोटो 4', 'mandir', 'approved'),
  ('assets/google-maps-5.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 5', 'mandir', 'approved'),
  ('assets/google-maps-6.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 6', 'mandir', 'approved'),
  ('assets/google-maps-7.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 7', 'mandir', 'approved'),
  ('assets/google-maps-8.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 8', 'mandir', 'approved'),
  ('assets/google-maps-9.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 9', 'mandir', 'approved'),
  ('assets/google-maps-10.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 10', 'mandir', 'approved'),
  ('assets/google-maps-11.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 11', 'mandir', 'approved'),
  ('assets/google-maps-12.jpg', 'मंदिर परिसर का दृश्य', 'Temple premises view (Google Maps user photo)', 'Google Maps उपयोगकर्ता फोटो — मंदिर परिसर 12', 'mandir', 'approved'),
  ('assets/temple-myadhyatm-1.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-2.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-3.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-4.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-5.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-6.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-7.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-myadhyatm-8.jpg', 'मंदिर एवं शिवलिंग का दृश्य', 'Temple and Shivalinga view (MyAdhyatm)', 'बाबा भदेश्वर नाथ मंदिर और शिवलिंग का दृश्य (MyAdhyatm)', 'shringar', 'approved'),
  ('assets/temple-amarujala-1.jpg', 'बाबा भदेश्वर नाथ मंदिर', 'Baba Bhadeshwar Nath Temple (Amar Ujala, 2018)', 'अमर उजाला फोटो — बाबा भदेश्वर नाथ मंदिर (2018)', 'mandir', 'approved'),
  ('assets/temple-amarujala-2.jpg', 'बाबा भदेश्वर नाथ मंदिर', 'Baba Bhadeshwar Nath Temple (Amar Ujala, 2018)', 'अमर उजाला फोटो — बाबा भदेश्वर नाथ मंदिर (2018)', 'mandir', 'approved'),
  ('assets/temple-amarujala-3.jpg', 'बाबा भदेश्वर नाथ', 'Baba Bhadeshwar Nath (Amar Ujala, 2021)', 'अमर उजाला फोटो — बाबा भदेश्वर नाथ (2021)', 'shringar', 'approved'),
  ('assets/temple-amarujala-4.jpg', 'बाबा भदेश्वर नाथ', 'Baba Bhadeshwar Nath (Amar Ujala, 2021)', 'अमर उजाला फोटो — बाबा भदेश्वर नाथ (2021)', 'shringar', 'approved'),
  ('assets/temple-amarujala-5.jpg', 'बाबा भदेश्वर नाथ मंदिर पर भक्तों की भीड़', 'Devotees at Baba Bhadeshwar Nath Temple (Amar Ujala, 2021)', 'अमर उजाला फोटो — मंदिर पर भक्तों की भीड़ (2021)', 'mela', 'approved'),
  ('assets/region-basti-board.jpg', 'बस्ती जिला — अब्दुल्ला बोर्ड', 'Basti district — Abdullah Board (Wikimedia Commons)', 'Wikimedia Commons CC फोटो — बस्ती जिला सड़क चिह्न', 'kshetra', 'approved'),
  ('assets/region-basti-railway.jpg', 'बस्ती रेलवे स्टेशन', 'Basti railway station (Wikimedia Commons, CC0)', 'Wikimedia Commons CC0 फोटो — बस्ती रेलवे स्टेशन', 'kshetra', 'approved'),
  ('assets/region-basti-platform.jpg', 'बस्ती रेलवे स्टेशन प्लेटफ़ॉर्म', 'Basti railway station platform (Wikimedia Commons)', 'Wikimedia Commons फोटो — बस्ती रेलवे स्टेशन प्लेटफ़ॉर्म', 'kshetra', 'approved'),
  ('assets/region-basti-1930s.jpg', '1930 का दशक — बस्ती का ऐतिहासिक दृश्य', '1930s historical view of Basti (Wikimedia Commons, Public Domain)', 'Wikimedia Commons Public Domain ऐतिहासिक फोटो — 1930 का दशक, बस्ती', 'kshetra', 'approved'),
  ('assets/region-nh28-basti.jpg', 'राष्ट्रीय राजमार्ग NH-28, बस्ती के पास', 'National Highway NH-28 near Basti (Wikimedia Commons)', 'Wikimedia Commons फोटो — NH-28 बस्ती के पास', 'kshetra', 'approved'),
  ('assets/region-amorha-chaturbhuji.jpg', 'चतुर्भुजी मंदिर, अमोरहा (बस्ती)', 'Chaturbhuji Mandir, Amorha, Basti (Wikimedia Commons)', 'Wikimedia Commons फोटो — चतुर्भुजी मंदिर, अमोरहा, बस्ती', 'kshetra', 'approved'),
  ('assets/region-amorha-kotahi.jpg', 'कोटाही मंदिर, अमोरहा (बस्ती)', 'Kotahi Mandir, Amorha, Basti (Wikimedia Commons)', 'Wikimedia Commons फोटो — कोटाही मंदिर, अमोरहा, बस्ती', 'kshetra', 'approved'),
  ('assets/region-amorha-ramrekha.jpg', 'रामरेखा मंदिर, अमोरहा (बस्ती)', 'Ramrekha Mandir, Amorha, Basti (Wikimedia Commons)', 'Wikimedia Commons फोटो — रामरेखा मंदिर, अमोरहा, बस्ती', 'kshetra', 'approved'),
  ('assets/region-amorha-raja-jhala.jpg', 'राजा ज्हाला सिंह स्मारक, अमोरहा (बस्ती)', 'Raja Jhala Singh memorial, Amorha, Basti (Wikimedia Commons)', 'Wikimedia Commons फोटो — राजा ज्हाला सिंह, अमोरहा, बस्ती', 'kshetra', 'approved')
on conflict do nothing;

insert into public.announcements (title, body, priority, status)
values ('आधिकारिक वेबसाइट लॉन्च',
        'बाबा भदेश्वर नाथ मंदिर, बस्ती की आधिकारिक वेबसाइट अब उपलब्ध है। मंदिर समिति की घोषणाएँ यहाँ प्रकाशित होंगी।',
        1, 'approved')
on conflict do nothing;

commit;
