# Jalaram Events

Production-ready event & vendor management platform (Flutter + Supabase).

## Quick Start

```bash
flutter pub get
cp .env.example .env         # fill Supabase URL + anon key
supabase start && supabase db push
flutter run
```

## Stack

- **Mobile**: Flutter 3.24 · Riverpod · go_router · easy_localization
- **Backend**: Supabase (Postgres + Auth + Storage + Realtime + Edge Functions)
- **Auth**: Google · Apple · Facebook · Phone OTP · Email — role-based routing
- **Roles**: `client`, `vendor`, `admin`, `super_admin`, `support` (JWT claim + RLS)
- **i18n**: en · hi · gu · mr · ta
- **Payments**: Razorpay

## Structure

```
lib/
  core/       config, theme, auth, router
  features/   auth, client, vendor, admin, onboarding
supabase/
  migrations/ schema + RLS + seed
assets/i18n/  5 locales
```

See `.github/workflows/` for CI/CD pipelines. Tag `vX.Y.Z` to ship mobile releases.
