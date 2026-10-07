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

create policy "anyone may submit a photo for moderation"
  on public.photos for insert
  to anon
  with check (status = 'pending' and storage_path like 'submissions/%');

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
  'aarti', 'approved')
on conflict do nothing;

insert into public.announcements (title, body, priority, status)
values ('आधिकारिक वेबसाइट लॉन्च',
        'बाबा भदेश्वर नाथ मंदिर, बस्ती की आधिकारिक वेबसाइट अब उपलब्ध है। मंदिर समिति की घोषणाएँ यहाँ प्रकाशित होंगी।',
        1, 'approved')
on conflict do nothing;

commit;
