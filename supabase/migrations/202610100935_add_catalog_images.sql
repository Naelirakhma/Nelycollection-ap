alter table public.jasa_jahit
  add column if not exists image_url text;

alter table public.kebaya
  add column if not exists image_url text;

alter table public.galeri
  add column if not exists image_url text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'nely-uploads',
  'nely-uploads',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "NELY catalog images are publicly readable"
  on storage.objects;
create policy "NELY catalog images are publicly readable"
on storage.objects
for select
to public
using (bucket_id = 'nely-uploads');

drop policy if exists "NELY admins can upload catalog images"
  on storage.objects;
create policy "NELY admins can upload catalog images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'nely-uploads'
  and exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.role = 'admin'
  )
);

drop policy if exists "NELY admins can update catalog images"
  on storage.objects;
create policy "NELY admins can update catalog images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'nely-uploads'
  and exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.role = 'admin'
  )
)
with check (
  bucket_id = 'nely-uploads'
  and exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.role = 'admin'
  )
);

drop policy if exists "NELY admins can delete catalog images"
  on storage.objects;
create policy "NELY admins can delete catalog images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'nely-uploads'
  and exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.role = 'admin'
  )
);

notify pgrst, 'reload schema';
