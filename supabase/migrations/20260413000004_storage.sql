-- Storage buckets
insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('portfolios', 'portfolios', true),
  ('documents', 'documents', false)
on conflict (id) do nothing;

-- Avatars: users can upload their own
create policy "avatars: public read" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "avatars: owner upload" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]
  );
create policy "avatars: owner update" on storage.objects
  for update using (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Portfolios: vendor-owned
create policy "portfolios: public read" on storage.objects
  for select using (bucket_id = 'portfolios');
create policy "portfolios: vendor upload" on storage.objects
  for insert with check (
    bucket_id = 'portfolios' and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Documents: owner + staff only
create policy "documents: owner read" on storage.objects
  for select using (
    bucket_id = 'documents' and (
      auth.uid()::text = (storage.foldername(name))[1]
      or public.is_staff()
    )
  );
create policy "documents: owner upload" on storage.objects
  for insert with check (
    bucket_id = 'documents' and auth.uid()::text = (storage.foldername(name))[1]
  );
