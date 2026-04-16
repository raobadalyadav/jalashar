-- ============ EXPANDED SCHEMA ============

-- Cities master (for dropdowns + seo)
create table if not exists public.cities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  state text not null,
  country text not null default 'India',
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Vendor categories (replaces hard-coded strings, supports i18n)
create table if not exists public.vendor_categories (
  slug text primary key,
  name text not null,
  icon text,
  sort_order int default 0,
  is_active boolean default true
);

-- Vendor availability (blocked dates)
create table if not exists public.vendor_availability (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  blocked_date date not null,
  reason text,
  created_at timestamptz default now(),
  unique (vendor_id, blocked_date)
);
create index if not exists va_vendor_date on public.vendor_availability(vendor_id, blocked_date);

-- Vendor custom pricing packages
create table if not exists public.vendor_packages (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  name text not null,
  description text,
  price numeric(10,2) not null,
  duration_hours int,
  features jsonb default '[]'::jsonb,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Promo codes / coupons
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  description text,
  discount_type text not null check (discount_type in ('percent','flat')),
  discount_value numeric(10,2) not null,
  min_order numeric(10,2) default 0,
  max_discount numeric(10,2),
  valid_from timestamptz default now(),
  valid_until timestamptz,
  usage_limit int,
  used_count int default 0,
  is_active boolean default true
);

-- Track coupon use per booking
create table if not exists public.booking_coupons (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  coupon_id uuid not null references public.coupons(id),
  discount_applied numeric(10,2) not null,
  applied_at timestamptz default now()
);

-- Referral program
create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.users(id) on delete cascade,
  referee_id uuid references public.users(id) on delete set null,
  code text unique not null,
  status text default 'pending' check (status in ('pending','completed','expired')),
  reward_amount numeric(10,2) default 200,
  created_at timestamptz default now(),
  completed_at timestamptz
);

-- Event checklist templates (per event type)
create table if not exists public.checklist_templates (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  title text not null,
  items jsonb not null default '[]'::jsonb
);

-- User-specific checklist items for a booking
create table if not exists public.booking_checklist (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  title text not null,
  is_done boolean default false,
  due_date date,
  sort_order int default 0,
  created_at timestamptz default now()
);
create index if not exists bc_booking on public.booking_checklist(booking_id);

-- Vendor payouts
create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  amount numeric(10,2) not null,
  status text default 'pending' check (status in ('pending','processing','paid','failed')),
  method text,
  reference text,
  created_at timestamptz default now(),
  paid_at timestamptz
);
create index if not exists payouts_vendor on public.payouts(vendor_id, created_at desc);

-- Banners (admin-managed home hero carousel)
create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,
  action_url text,
  sort_order int default 0,
  is_active boolean default true,
  valid_from timestamptz default now(),
  valid_until timestamptz
);

-- FAQ
create table if not exists public.faqs (
  id uuid primary key default gen_random_uuid(),
  category text,
  question text not null,
  answer text not null,
  sort_order int default 0,
  is_active boolean default true
);

-- Support tickets
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject text not null,
  message text not null,
  status text default 'open' check (status in ('open','in_progress','resolved','closed')),
  priority text default 'normal' check (priority in ('low','normal','high','urgent')),
  booking_id uuid references public.bookings(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Booking addons
create table if not exists public.booking_addons (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  name text not null,
  price numeric(10,2) not null,
  quantity int default 1,
  created_at timestamptz default now()
);

-- ============ RLS ============
alter table public.cities enable row level security;
alter table public.vendor_categories enable row level security;
alter table public.vendor_availability enable row level security;
alter table public.vendor_packages enable row level security;
alter table public.coupons enable row level security;
alter table public.booking_coupons enable row level security;
alter table public.referrals enable row level security;
alter table public.checklist_templates enable row level security;
alter table public.booking_checklist enable row level security;
alter table public.payouts enable row level security;
alter table public.banners enable row level security;
alter table public.faqs enable row level security;
alter table public.support_tickets enable row level security;
alter table public.booking_addons enable row level security;

-- Public-read catalogs
create policy "cities: public read" on public.cities for select using (true);
create policy "cats: public read" on public.vendor_categories for select using (true);
create policy "avail: public read" on public.vendor_availability for select using (true);
create policy "vpkg: public read" on public.vendor_packages for select using (is_active);
create policy "coupons: public read" on public.coupons for select using (is_active);
create policy "checklist_templates: public read" on public.checklist_templates for select using (true);
create policy "banners: public read" on public.banners for select using (is_active);
create policy "faqs: public read" on public.faqs for select using (is_active);

-- Vendor availability: vendor owns
create policy "avail: owner write" on public.vendor_availability for all
  using (vendor_id in (select id from public.vendors where user_id = auth.uid()) or public.is_staff())
  with check (vendor_id in (select id from public.vendors where user_id = auth.uid()) or public.is_staff());

create policy "vpkg: owner write" on public.vendor_packages for all
  using (vendor_id in (select id from public.vendors where user_id = auth.uid()) or public.is_staff())
  with check (vendor_id in (select id from public.vendors where user_id = auth.uid()) or public.is_staff());

-- Staff-managed
create policy "cities: staff write" on public.cities for all using (public.is_staff()) with check (public.is_staff());
create policy "cats: staff write" on public.vendor_categories for all using (public.is_staff()) with check (public.is_staff());
create policy "coupons: staff write" on public.coupons for all using (public.is_staff()) with check (public.is_staff());
create policy "banners: staff write" on public.banners for all using (public.is_staff()) with check (public.is_staff());
create policy "faqs: staff write" on public.faqs for all using (public.is_staff()) with check (public.is_staff());
create policy "checklist_templates: staff write" on public.checklist_templates for all using (public.is_staff()) with check (public.is_staff());

-- Booking-scoped
create policy "bcoupons: participant read" on public.booking_coupons for select
  using (booking_id in (select id from public.bookings where client_id = auth.uid()) or public.is_staff());
create policy "bcoupons: client insert" on public.booking_coupons for insert
  with check (booking_id in (select id from public.bookings where client_id = auth.uid()));

create policy "bchecklist: participant read" on public.booking_checklist for select
  using (booking_id in (select id from public.bookings where client_id = auth.uid()) or public.is_staff());
create policy "bchecklist: client write" on public.booking_checklist for all
  using (booking_id in (select id from public.bookings where client_id = auth.uid()))
  with check (booking_id in (select id from public.bookings where client_id = auth.uid()));

create policy "baddons: participant read" on public.booking_addons for select
  using (booking_id in (select id from public.bookings where client_id = auth.uid()) or public.is_staff());
create policy "baddons: client write" on public.booking_addons for all
  using (booking_id in (select id from public.bookings where client_id = auth.uid()))
  with check (booking_id in (select id from public.bookings where client_id = auth.uid()));

-- Referrals
create policy "refs: own read" on public.referrals for select using (referrer_id = auth.uid() or referee_id = auth.uid() or public.is_staff());
create policy "refs: own insert" on public.referrals for insert with check (referrer_id = auth.uid());

-- Payouts
create policy "payouts: own read" on public.payouts for select
  using (vendor_id in (select id from public.vendors where user_id = auth.uid()) or public.is_staff());
create policy "payouts: staff write" on public.payouts for all using (public.is_staff()) with check (public.is_staff());

-- Support tickets
create policy "tickets: own read" on public.support_tickets for select using (user_id = auth.uid() or public.is_staff());
create policy "tickets: own insert" on public.support_tickets for insert with check (user_id = auth.uid());
create policy "tickets: staff update" on public.support_tickets for update using (public.is_staff());

-- ============ SEEDS ============
insert into public.cities (name, state) values
  ('Surat','Gujarat'),('Ahmedabad','Gujarat'),('Vadodara','Gujarat'),('Rajkot','Gujarat'),
  ('Mumbai','Maharashtra'),('Pune','Maharashtra'),('Delhi','Delhi'),('Bangalore','Karnataka')
on conflict (name) do nothing;

insert into public.vendor_categories (slug, name, icon, sort_order) values
  ('photographer','Photographer','camera_alt',1),
  ('videographer','Videographer','videocam',2),
  ('makeup','Makeup Artist','brush',3),
  ('dj','DJ & Sound','music_note',4),
  ('caterer','Caterer','restaurant',5),
  ('decorator','Decorator','celebration',6),
  ('mehendi','Mehendi Artist','pan_tool',7),
  ('pandit','Pandit','temple_hindu',8),
  ('florist','Florist','local_florist',9),
  ('venue','Venue','location_city',10)
on conflict (slug) do nothing;

insert into public.faqs (category, question, answer, sort_order) values
  ('Booking','How do I book a vendor?','Pick a service or vendor, choose your date, fill in event details, and pay 30% advance to confirm.',1),
  ('Booking','Can I cancel a booking?','Yes — cancellations made 7+ days before the event receive a full refund of the advance.',2),
  ('Payments','Is my payment secure?','All payments are processed by Razorpay with bank-grade encryption. Jalaram never stores card details.',3),
  ('Vendors','How are vendors verified?','Every vendor submits ID proof and portfolio samples, which our team reviews before listing.',4),
  ('Account','How do I change my language?','Go to Profile → Settings → Language and pick from 5 supported languages.',5)
on conflict do nothing;

insert into public.checklist_templates (event_type, title, items) values
  ('wedding','Wedding Checklist','["Book venue","Send invitations","Confirm caterer menu","Finalise decor theme","Photographer briefing","DJ playlist","Mehendi artist confirmation","Transportation","Guest accommodation","Final headcount"]'::jsonb),
  ('birthday','Birthday Checklist','["Book venue","Order cake","Decorations","Send invites","Entertainment","Return gifts","Photography","Catering menu"]'::jsonb),
  ('corporate','Corporate Event','["Venue booking","AV setup","Catering","Branding material","Guest list","Photographer","Speaker coordination","Transportation"]'::jsonb)
on conflict do nothing;

insert into public.banners (title, subtitle, sort_order) values
  ('Your Dream Wedding Awaits','From ₹1,50,000 · 45 days planning',1),
  ('Corporate Events Made Easy','Professional planning from ₹80,000',2),
  ('Birthday Celebrations','Memorable parties from ₹25,000',3)
on conflict do nothing;

insert into public.coupons (code, description, discount_type, discount_value, min_order, max_discount) values
  ('WELCOME10','10% off first booking','percent',10,10000,2000),
  ('FEST500','Flat ₹500 off','flat',500,5000,null)
on conflict (code) do nothing;
