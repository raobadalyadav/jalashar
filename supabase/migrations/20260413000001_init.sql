-- Jalaram Events: initial schema with RLS + roles
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "pg_trgm" with schema extensions;

-- ============ ENUMS ============
do $$ begin
  create type user_role as enum ('client','vendor','admin','super_admin','support');
exception when duplicate_object then null; end $$;

do $$ begin
  create type booking_status as enum ('pending','confirmed','in_progress','completed','cancelled','refunded');
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_status as enum ('created','authorized','captured','failed','refunded');
exception when duplicate_object then null; end $$;

-- ============ USERS ============
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  phone text,
  name text,
  avatar_url text,
  role user_role not null default 'client',
  locale text not null default 'en',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists users_role_idx on public.users(role);

-- Auto-create user row on signup + set JWT claim
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, email, phone)
  values (new.id, new.email, new.phone)
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Sync role → JWT custom claim (read via auth.jwt()->>'role')
create or replace function public.sync_user_role_to_jwt()
returns trigger language plpgsql security definer as $$
begin
  update auth.users
    set raw_app_meta_data =
      coalesce(raw_app_meta_data,'{}'::jsonb) || jsonb_build_object('role', new.role::text)
    where id = new.id;
  return new;
end $$;

drop trigger if exists users_role_sync on public.users;
create trigger users_role_sync
  after insert or update of role on public.users
  for each row execute function public.sync_user_role_to_jwt();

-- ============ VENDORS ============
create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  category text not null,
  bio text,
  city text,
  base_price numeric(10,2),
  is_verified boolean not null default false,
  rating_avg numeric(3,2) not null default 0,
  portfolio_urls text[] default '{}',
  service_area text[] default '{}',
  created_at timestamptz not null default now()
);
create index if not exists vendors_category_city_idx on public.vendors(category, city);
create index if not exists vendors_name_trgm on public.vendors using gin (bio extensions.gin_trgm_ops);

-- ============ SERVICES (packages) ============
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  base_price numeric(10,2) not null,
  planning_duration text,
  features jsonb default '[]'::jsonb,
  image_url text,
  is_active boolean default true
);

-- ============ BOOKINGS ============
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.users(id) on delete restrict,
  vendor_id uuid references public.vendors(id) on delete set null,
  service_id uuid references public.services(id) on delete set null,
  event_date date not null,
  status booking_status not null default 'pending',
  guest_count int,
  venue text,
  notes text,
  total_amount numeric(10,2) not null,
  advance_paid numeric(10,2) default 0,
  created_at timestamptz not null default now()
);
create index if not exists bookings_client_idx on public.bookings(client_id);
create index if not exists bookings_vendor_idx on public.bookings(vendor_id);
create index if not exists bookings_date_status on public.bookings(event_date, status);

-- ============ PAYMENTS ============
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  amount numeric(10,2) not null,
  method text,
  status payment_status not null default 'created',
  razorpay_order_id text,
  razorpay_payment_id text,
  created_at timestamptz not null default now()
);

-- ============ REVIEWS ============
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  client_id uuid not null references public.users(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  stars int not null check (stars between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

-- ============ MESSAGES ============
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  receiver_id uuid not null references public.users(id) on delete cascade,
  content text not null,
  is_read boolean default false,
  created_at timestamptz not null default now()
);
create index if not exists messages_booking_idx on public.messages(booking_id, created_at desc);

-- ============ NOTIFICATIONS ============
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text,
  type text,
  ref_id uuid,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

-- ============ TRANSLATIONS ============
create table if not exists public.translations (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  locale text not null,
  field text not null,
  value text not null,
  unique (entity_type, entity_id, locale, field)
);

-- ============ AUDIT LOG ============
create table if not exists public.audit_logs (
  id bigserial primary key,
  user_id uuid,
  action text not null,
  entity text,
  entity_id uuid,
  meta jsonb,
  created_at timestamptz not null default now()
);
