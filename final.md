---

## Complete Feature List — Jalaram Platform (Free Model)

---

### Platform Model — Zero Transaction Policy

The platform earns nothing per booking. No Razorpay, no UPI, no payment gateway at all. Customer dekhta hai vendor ka poora profile — name, phone, price, portfolio — aur directly unse contact karta hai. Payment cash ya UPI bahar hoti hai. Platform sirf ek free directory + booking coordination tool hai.

**What the platform stores and shows publicly:**
- Vendor's full name, phone number, WhatsApp link
- Portfolio photos and video reels
- Package prices and descriptions
- Service area and city
- Availability calendar
- All reviews and ratings
- Social media links

---

### Customer / Client — Full Feature List

**Account**
- Register with email OTP/email with password/google login/facebook login
- Google sign-in option
- Profile: name, city, profile photo
- Notification preferences

**Discovery**
- Browse all vendors by category (Makeup, Photography, Videography, DJ, Decoration, Catering, Mehendi, Pandit Ji, Florist, Band, Sound & Light, Choreographer)
- Search by vendor name or keyword
- Filter by city / area / pin code
- Filter by budget range (e.g. ₹5,000 – ₹50,000)
- Filter by event type (Wedding, Birthday, Corporate, Engagement, Anniversary, Festival)
- Filter by availability on specific date
- Sort by: highest rated, most booked, price low-to-high, newest
- Verified vendors only toggle

**Vendor Profile Page (full transparency)**
- Business name + owner name
- Phone number + WhatsApp direct link
- Full address + Google Maps pin
- Category and sub-services offered
- Years of experience
- Number of events done
- All portfolio photos (up to 30)
- Video reels / showreel
- Package list with names and prices
- Service area (which cities they cover)
- Languages spoken
- Instagram / YouTube / Facebook links
- All reviews with star rating and photos
- Average rating display
- Availability calendar (green = free, red = booked)

**Booking Request System**
- Send booking request: event type, date, venue, guest count, notes
- Track status: Requested → Vendor Accepted → Confirmed → Event Done
- Cancel request anytime before acceptance
- Reschedule request (send new date via chat)
- Download booking confirmation card (PDF / share image)
- My Bookings screen with upcoming events + countdown timer

**Communication**
- In-app chat with vendor per booking
- Send images in chat (reference looks, mood board)
- See message read/delivered status
- Direct call button (opens dialer with vendor's number)
- Direct WhatsApp button (opens WhatsApp with vendor)
- Chat history saved permanently per booking

**Post-Event**
- Rate vendor (1–5 stars) after event is marked done
- Write review with text + upload event photos
- View full review before writing (so they know what's expected)
- Report vendor (fake profile, rude behavior, no-show)

**Extra Tools**
- Wishlist / Save vendors (bookmark for later)
- Compare vendors side-by-side (up to 3)
- Budget estimator — enter event type + guest count, get rough cost breakdown
- Event checklist — auto-generated list based on event type (e.g. Wedding = 28-point checklist)
- Share vendor profile link via WhatsApp, copy link
- Referral code — share with friends, both get platform perks (premium visibility for vendors, priority listing)
- Guest Invite feature — share event details link with family to help coordinate vendor contacts

---

### Vendor / Artist — Full Feature List

**Account & Onboarding**
- Register with email OTP/email with password/google login/facebook login
- Select category/categories (a photographer can also list videography)
- Complete profile setup with guided steps
- Profile completion % meter with tips to improve

**Profile Building**
- Business name, personal name, tagline / one-liner
- Phone, WhatsApp number (can be different)
- Full address + set location pin on map
- About / bio (up to 500 characters)
- Upload up to 30 portfolio photos
- Upload up to 5 video reels (stored on Supabase Storage)
- Create packages: package name, description, price, what's included
- Set service cities / areas (multi-select)
- Languages spoken
- Instagram, YouTube, Facebook links
- Starting price display on card

**Availability Management**
- Calendar: tap date to mark as free or busy
- Block date ranges (for holidays or personal events)
- Set max events per day (e.g. only 1 wedding per day)
- "Fully booked this month" toggle

**Booking Management**
- Push notification + in-app alert on every new booking request
- View full request: customer name, phone, event type, date, venue, guest count, notes
- Accept booking with optional welcome message
- Decline booking with reason (date blocked, outside area, etc.)
- All upcoming confirmed bookings in timeline view
- Mark booking as "Event Completed" to trigger review request to customer
- Full booking history

**Communication**
- In-app chat with customer per booking
- Send images (reference looks, past work samples)
- Quick reply templates (e.g. "Thank you! I'll contact you 2 days before the event")
- See when customer was last active

**Visibility & Analytics**
- Verified badge (applied for, checked by admin)
- Featured listing badge (given by admin, rotated fairly)
- Profile views count (7-day, 30-day)
- Search appearances count
- Booking requests received counter
- Accepted vs declined bookings ratio
- Shareable profile link (use on Instagram bio, visiting card, WhatsApp status)

**Vendor Dashboard Home**
- Today's bookings
- Pending requests with counter
- Upcoming events this week
- Average rating + total reviews
- Quick access to chat

---

### Admin (Jalaram Team) — Full Feature List

**User Management**
- View all registered customers with profile info
- View all vendor registrations with documents
- Approve or reject vendor listing
- Grant Verified badge manually
- Suspend account (temporary) or ban (permanent)
- Reset user issues / account recovery

**Vendor Control**
- Mark vendor as Featured (gets top listing)
- Remove Featured status
- Edit or override vendor details if wrong
- Delete fake / fraudulent profiles
- View a vendor's full booking history

**Content Moderation**
- View all reported vendors / reviews
- Remove inappropriate reviews or photos
- Resolve customer complaints about vendors
- Flag suspicious activity (fake reviews, spam)

**Platform Management**
- Manage Jalaram service packages (edit name, price, features, photos)
- Add / remove event categories
- Send broadcast push notification to all users / vendors / both
- Pinned announcement banner in app

**Analytics Dashboard**
- Total users (customers + vendors)
- New registrations per day/week/month
- Total booking requests created
- Accepted vs declined bookings
- Most popular vendor categories
- Most searched cities
- App opens / active users (from Firebase Analytics)

---

### Supabase Tables — Updated (No Payments Table)

| Table | Key Fields |
|---|---|
| `users` | id, name, phone, role, city, avatar_url |
| `vendors` | id, user_id, category, bio, city, base_price, is_verified, is_featured, rating_avg, portfolio_urls |
| `services` | id, name, description, base_price, planning_duration, features, event_type |
| `bookings` | id, client_id, vendor_id, service_id, event_date, event_type, venue, guest_count, notes, status |
| `messages` | id, booking_id, sender_id, receiver_id, content, image_url, is_read, created_at |
| `reviews` | id, booking_id, client_id, vendor_id, stars, comment, photos, created_at |
| `notifications` | id, user_id, title, body, type, ref_id, is_read |
| `reports` | id, reporter_id, reported_id, reason, status, created_at |
| `saved_vendors` | id, user_id, vendor_id |

Payments table — removed entirely. No Razorpay, no transaction logs, no nothing. Poora payment system bahar hai platform ke.

---

### Tech Stack — Simplified (No Payment Gateway)

| Layer | Choice |
|---|---|
| App | Flutter (Android first, iOS later) |
| Backend | Supabase (Auth + DB + Storage + Realtime) |
| Push Notifications | Firebase Cloud Messaging (FCM) — free |
| Maps | Google Maps Flutter plugin |
| Image Storage | Supabase Storage (5 GB free tier) |
| Chat | Supabase Realtime (websocket subscriptions) |
| State Management | Riverpod |
| PDF Generation | `pdf` Flutter package (booking confirmation) |

**No Razorpay. No payment SDK. No webhook. Zero.** Saves setup time, avoids compliance (PCI-DSS), and removes any legal liability for the platform.

---

### MVP Build Order (Revised)

1. Auth register with email OTP/email with password/google login/facebook login + user/vendor roles
2. Vendor profile create + edit + portfolio upload
3. Browse / search / filter vendors
4. Vendor profile detail page (full info visible)
5. Send booking request flow
6. Accept / decline booking (vendor side)
7. In-app chat (Supabase Realtime)
8. Push notifications (FCM)
9. Reviews & ratings post-event
10. Admin panel (approve vendors, featured, ban)
11. Wishlist, compare, share profile
12. Event checklist + budget estimator tools
