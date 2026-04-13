-- Wishlist (client shortlists vendors)
create table if not exists public.wishlist (
  user_id uuid not null references public.users(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, vendor_id)
);

alter table public.wishlist enable row level security;

create policy "wishlist: own read" on public.wishlist
  for select using (user_id = auth.uid());
create policy "wishlist: own write" on public.wishlist
  for insert with check (user_id = auth.uid());
create policy "wishlist: own delete" on public.wishlist
  for delete using (user_id = auth.uid());

-- Keep vendor rating in sync when reviews change
create or replace function public.refresh_vendor_rating()
returns trigger language plpgsql security definer as $$
declare
  vid uuid := coalesce(new.vendor_id, old.vendor_id);
begin
  update public.vendors
  set rating_avg = coalesce(
    (select round(avg(stars)::numeric, 2) from public.reviews where vendor_id = vid),
    0
  )
  where id = vid;
  return coalesce(new, old);
end $$;

drop trigger if exists reviews_rating_sync on public.reviews;
create trigger reviews_rating_sync
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_vendor_rating();
