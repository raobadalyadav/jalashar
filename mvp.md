---

## 🎯 Jalaram Event & Management — MVP Plan

---

### Phase 1 — Foundation (Weeks 1–3)

**Project Setup**
- Flutter project init with `flutter_supabase` SDK
- Supabase project setup (free tier → scale up)
- Folder structure: `features/`, `shared/`, `core/`
- Flavors: dev / staging / prod
- Git repo + CI with GitHub Actions

**Supabase Schema (Core Tables)**
- `users` — id, name, phone, role (client/vendor/admin), avatar_url, created_at
- `vendors` — id, user_id, category (makeup/photo/dj/decorator/caterer...), bio, city, base_price, is_verified, rating_avg
- `services` — id, name (Wedding/Birthday/Corporate...), description, base_price, planning_duration, features JSON
- `bookings` — id, client_id, vendor_id, service_id, event_date, status, total_amount, advance_paid
- `payments` — id, booking_id, amount, method, status, razorpay_order_id, created_at
- `reviews` — id, booking_id, client_id, vendor_id, stars, comment, created_at
- `messages` — id, booking_id, sender_id, receiver_id, content, is_read, created_at
- `notifications` — id, user_id, title, body, type, is_read, ref_id

**Auth Module**
- Phone OTP login (via Supabase Auth + SMS)
- Google OAuth login
- Role selection on first login (Client or Vendor)
- JWT session management + auto-refresh
- Row Level Security (RLS) policies on all tables

---

### Phase 2 — Client-Facing Features (Weeks 4–7)

**Home Screen**
- Hero banner with featured packages (Wedding, Corporate, Birthday, etc.)
- Category chips: Birthday · Engagement · Wedding · Corporate · Anniversary · Festival
- Search bar with city + date filter
- "Trending vendors near you" section (Google Maps proximity)

**Service Packages (from your list)**
- Package cards: name, price (₹25,000 – ₹1,50,000+), planning duration badge
- "Key Features" expandable list (all 8+ features per package)
- "Book Now" CTA → booking flow
- "Details" → full service detail page

**Vendor Marketplace (★ key differentiator)**
- Category filters: Makeup Artist · Photographer · Videographer · DJ · Caterer · Decorator · Mehendi · Pandit · Florist · Sound & Light
- Vendor card: photo, name, city, rating, price-from
- Vendor profile page: portfolio gallery, about, services offered, pricing tiers, reviews, availability calendar
- "Contact" button → opens in-app chat

**Booking Flow**
- Step 1: Select service or vendor → pick date
- Step 2: Event details form (type, guest count, venue, special notes)
- Step 3: Price summary + payment options (advance 30% / full)
- Step 4: Razorpay/UPI payment integration
- Step 5: Booking confirmation screen + PDF receipt

**My Bookings (Client Dashboard)**
- Upcoming events with countdown
- Booking status: Pending → Confirmed → In Progress → Completed
- View assigned vendors per booking
- Cancel / Reschedule request
- Post-event: rate & review each vendor

---

### Phase 3 — Vendor-Facing Features (Weeks 8–10)

**Vendor Onboarding**
- Category selection (single or multi-service)
- Portfolio upload (up to 20 photos → Supabase Storage)
- Pricing setup (base price + add-on packages)
- Service area / city coverage
- Document upload (ID proof for verification)

**Vendor Dashboard**
- Booking requests (Accept / Decline with reason)
- Earnings summary: total earned, pending payout, this month
- Availability calendar (block dates)
- My reviews & rating breakdown (5-star graph)

**In-App Chat**
- Real-time messaging per booking (Supabase Realtime subscriptions)
- Image attachment support
- Read receipts
- Auto-message: "Booking confirmed, vendor will contact you soon"

---

### Phase 4 — Admin Panel + Polish (Weeks 11–13)

**Admin Dashboard (Flutter Web or separate panel)**
- User management: verify vendors, ban/suspend users
- Booking overview: all bookings, status, revenue
- Commission settings (e.g. 10% platform fee per booking)
- Push notification broadcast (via FCM)
- Service package management: edit prices, features, images

**Notifications**
- FCM push: booking confirmed, new message, payment received, review received
- In-app notification bell with badge count
- Email confirmations via Supabase Edge Functions → Resend.com

**Additional Smart Features**
- Saved/Wishlist vendors (client can shortlist vendors)
- Compare vendors side-by-side (max 3)
- Event checklist generator (auto-generated based on event type)
- Referral code system (₹200 credit per successful referral)
- Shareable event booking link (for family coordination)

---

### Tech Stack Summary

| Layer | Technology |
|---|---|
| Mobile App | Flutter (iOS + Android) |
| Backend | Supabase (Auth + Postgres + Storage + Realtime) |
| Payments | Razorpay SDK (UPI, cards, net banking) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Maps & Location | Google Maps Flutter plugin |
| Edge Functions | Supabase Edge Functions (Deno) |
| Email | Resend.com via Edge Function |
| State Management | Riverpod or Bloc |
| Image Hosting | Supabase Storage (CDN-backed) |

---

### MVP Launch Checklist

- Supabase RLS on every table (security first)
- Phone OTP + Google login working
- At least 5 vendor categories live with real vendor data
- All 6 Jalaram service packages bookable end-to-end
- Razorpay test mode → live mode switch
- FCM push notifications for booking events
- Admin can approve/reject vendor registrations
- App Store + Play Store submission (TestFlight first)
- Privacy policy + Terms of Service page (required for stores)

---

### Post-MVP V2 Ideas

- AI-powered event budget estimator
- Live event tracking (vendor check-in via QR)
- Video call consultation booking with vendors
- Loyalty points / rewards system
- Multi-language support (Hindi, Gujarati, English)
- B2B corporate event portal (separate login)
- Vendor payout automation via Razorpay Route

---

**Estimated MVP Timeline: 13 weeks** with a team of 1–2 Flutter devs + 1 backend (Supabase config + Edge Functions). Supabase free tier handles up to ~50K active users before needing a Pro plan ($25/month). Razorpay charges 2% per transaction with no setup fee.