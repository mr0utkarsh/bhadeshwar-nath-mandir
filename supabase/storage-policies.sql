-- ============================================================================
-- Storage bucket "temple-photos" policies (run in SQL Editor AFTER creating
-- the bucket: Storage → Buckets → New bucket → name: temple-photos, Public ✓)
-- Public uploads land in submissions/ and are moderated before display.
-- Committee uploads land in photos/ and are inserted into public.photos.
-- ============================================================================

-- Public read access (bucket is public; policies keep writes restricted)
create policy "public read access"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'temple-photos');

-- Anyone (even signed-out visitors) may upload a submission for moderation
create policy "anyone may upload submissions"
on storage.objects for insert
to anon
with check (
  bucket_id = 'temple-photos'
  and (storage.foldername(name))[1] = 'submissions'
);

-- Committee members may upload final photos
create policy "committee may upload photos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'temple-photos'
  and (storage.foldername(name))[1] = 'photos'
  and exists (select 1 from public.admins where user_id = auth.uid())
);

-- Committee members may update/delete any object in the bucket
create policy "committee may update objects"
on storage.objects for update
to authenticated
using (
  bucket_id = 'temple-photos'
  and exists (select 1 from public.admins where user_id = auth.uid())
)
with check (
  bucket_id = 'temple-photos'
  and exists (select 1 from public.admins where user_id = auth.uid())
);

create policy "committee may delete objects"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'temple-photos'
  and exists (select 1 from public.admins where user_id = auth.uid())
);
