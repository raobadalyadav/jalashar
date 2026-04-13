-- Row Level Security policies
alter table public.users enable row level security;
alter table public.vendors enable row level security;
alter table public.services enable row level security;
alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.reviews enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.translations enable row level security;
alter table public.audit_logs enable row level security;

-- Helper: is staff
create or replace function public.is_staff() returns boolean
language sql stable as $$
  select coalesce(auth.jwt()->>'role' in ('admin','super_admin','support'), false);
$$;

-- ===== USERS =====
create policy "users: read self or staff" on public.users
  for select using (auth.uid() = id or public.is_staff());
create policy "users: update self" on public.users
  for update using (auth.uid() = id);
create policy "users: staff can update all" on public.users
  for update using (public.is_staff());

-- ===== VENDORS =====
create policy "vendors: public read" on public.vendors
  for select using (true);
create policy "vendors: owner insert" on public.vendors
  for insert with check (user_id = auth.uid());
create policy "vendors: owner update" on public.vendors
  for update using (user_id = auth.uid() or public.is_staff());
create policy "vendors: staff delete" on public.vendors
  for delete using (public.is_staff());

-- ===== SERVICES =====
create policy "services: public read" on public.services
  for select using (is_active = true or public.is_staff());
create policy "services: staff write" on public.services
  for all using (public.is_staff()) with check (public.is_staff());

-- ===== BOOKINGS =====
create policy "bookings: participants read" on public.bookings
  for select using (
    client_id = auth.uid()
    or vendor_id in (select id from public.vendors where user_id = auth.uid())
    or public.is_staff()
  );
create policy "bookings: client insert" on public.bookings
  for insert with check (client_id = auth.uid());
create policy "bookings: participants update" on public.bookings
  for update using (
    client_id = auth.uid()
    or vendor_id in (select id from public.vendors where user_id = auth.uid())
    or public.is_staff()
  );

-- ===== PAYMENTS =====
create policy "payments: owner read" on public.payments
  for select using (
    booking_id in (select id from public.bookings where client_id = auth.uid())
    or public.is_staff()
  );
create policy "payments: staff write" on public.payments
  for all using (public.is_staff()) with check (public.is_staff());

-- ===== REVIEWS =====
create policy "reviews: public read" on public.reviews
  for select using (true);
create policy "reviews: client insert own" on public.reviews
  for insert with check (client_id = auth.uid());
create policy "reviews: client update own" on public.reviews
  for update using (client_id = auth.uid());

-- ===== MESSAGES =====
create policy "messages: participants read" on public.messages
  for select using (sender_id = auth.uid() or receiver_id = auth.uid() or public.is_staff());
create policy "messages: sender insert" on public.messages
  for insert with check (sender_id = auth.uid());

-- ===== NOTIFICATIONS =====
create policy "notifications: own read" on public.notifications
  for select using (user_id = auth.uid() or public.is_staff());
create policy "notifications: own update" on public.notifications
  for update using (user_id = auth.uid());

-- ===== TRANSLATIONS =====
create policy "translations: public read" on public.translations
  for select using (true);
create policy "translations: staff write" on public.translations
  for all using (public.is_staff()) with check (public.is_staff());

-- ===== AUDIT =====
create policy "audit: staff read" on public.audit_logs
  for select using (public.is_staff());
