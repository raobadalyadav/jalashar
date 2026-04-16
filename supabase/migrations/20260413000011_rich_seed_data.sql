-- ============================================================
-- RICH SEED DATA — 30-40 rows across all entity types
-- Run this AFTER the base schema migrations (001–010)
-- ============================================================

-- ── 1. ADDITIONAL CITIES ────────────────────────────────────
INSERT INTO public.cities (name, state) VALUES
  ('Jaipur',       'Rajasthan'),
  ('Udaipur',      'Rajasthan'),
  ('Jodhpur',      'Rajasthan'),
  ('Indore',       'Madhya Pradesh'),
  ('Bhopal',       'Madhya Pradesh'),
  ('Nagpur',       'Maharashtra'),
  ('Nashik',       'Maharashtra'),
  ('Hyderabad',    'Telangana'),
  ('Chennai',      'Tamil Nadu'),
  ('Kolkata',      'West Bengal'),
  ('Lucknow',      'Uttar Pradesh'),
  ('Agra',         'Uttar Pradesh'),
  ('Chandigarh',   'Punjab'),
  ('Amritsar',     'Punjab')
ON CONFLICT (name) DO NOTHING;

-- ── 2. UPDATE BANNERS with Unsplash image URLs ───────────────
UPDATE public.banners
SET image_url = 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=1200&q=80'
WHERE title = 'Your Dream Wedding Awaits';

UPDATE public.banners
SET image_url = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80'
WHERE title = 'Corporate Events Made Easy';

UPDATE public.banners
SET image_url = 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=1200&q=80'
WHERE title = 'Birthday Celebrations';

INSERT INTO public.banners (title, subtitle, image_url, sort_order, is_active) VALUES
  ('Capture Every Moment',     'Top photographers from ₹15,000',   'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=1200&q=80', 4, true),
  ('Decorate Your Dream',      'Stunning decorations from ₹20,000', 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200&q=80', 5, true),
  ('Delicious Feasts',         'Catering for 100–500+ guests',     'https://images.unsplash.com/photo-1555244162-803834f70033?w=1200&q=80', 6, true),
  ('Music & Entertainment',    'DJs & Bands from ₹8,000',          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80', 7, true)
ON CONFLICT DO NOTHING;

-- ── 3. VENDOR CATEGORIES (update icons) ─────────────────────
UPDATE public.vendor_categories SET icon = 'camera_alt'       WHERE slug = 'photographer';
UPDATE public.vendor_categories SET icon = 'videocam'          WHERE slug = 'videographer';
UPDATE public.vendor_categories SET icon = 'face_retouching_natural' WHERE slug = 'makeup';
UPDATE public.vendor_categories SET icon = 'queue_music'       WHERE slug = 'dj';
UPDATE public.vendor_categories SET icon = 'restaurant'        WHERE slug = 'caterer';
UPDATE public.vendor_categories SET icon = 'celebration'       WHERE slug = 'decorator';

INSERT INTO public.vendor_categories (slug, name, icon, sort_order) VALUES
  ('band',         'Live Band',         'music_note',         11),
  ('caricature',   'Caricature Artist', 'brush',              12),
  ('horse',        'Horse & Rath',      'directions_run',     13),
  ('tent',         'Tent & Furniture',  'chair',              14),
  ('invitation',   'Invitation Design', 'card_giftcard',      15),
  ('choreographer','Choreographer',     'accessibility_new',  16)
ON CONFLICT (slug) DO NOTHING;

-- ── 4. UPDATE SERVICES with image URLs ──────────────────────
UPDATE public.services SET image_url = 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=800&q=80' WHERE slug = 'wedding';
UPDATE public.services SET image_url = 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=800&q=80' WHERE slug = 'engagement';
UPDATE public.services SET image_url = 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&q=80' WHERE slug = 'birthday';
UPDATE public.services SET image_url = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80' WHERE slug = 'corporate';
UPDATE public.services SET image_url = 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=800&q=80' WHERE slug = 'anniversary';
UPDATE public.services SET image_url = 'https://images.unsplash.com/photo-1555244162-803834f70033?w=800&q=80' WHERE slug = 'festival';

-- ── 5. SEED VENDORS (via auth.users + public.users + vendors) ─
DO $$
DECLARE
  uid1  uuid := '11111111-0000-0000-0000-000000000001';
  uid2  uuid := '11111111-0000-0000-0000-000000000002';
  uid3  uuid := '11111111-0000-0000-0000-000000000003';
  uid4  uuid := '11111111-0000-0000-0000-000000000004';
  uid5  uuid := '11111111-0000-0000-0000-000000000005';
  uid6  uuid := '11111111-0000-0000-0000-000000000006';
  uid7  uuid := '11111111-0000-0000-0000-000000000007';
  uid8  uuid := '11111111-0000-0000-0000-000000000008';
  uid9  uuid := '11111111-0000-0000-0000-000000000009';
  uid10 uuid := '11111111-0000-0000-0000-000000000010';
BEGIN

  -- Insert into auth.users (seed users, bypassing email confirmation)
  BEGIN
    INSERT INTO auth.users (id, email, role, aud, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
    VALUES
      (uid1,  'rahul.sharma@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Rahul Sharma"}'::jsonb),
      (uid2,  'priya.mehta@demo.in',      'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Priya Mehta"}'::jsonb),
      (uid3,  'arjun.patel@demo.in',      'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Arjun Patel"}'::jsonb),
      (uid4,  'sunita.desai@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Sunita Desai"}'::jsonb),
      (uid5,  'vikram.joshi@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Vikram Joshi"}'::jsonb),
      (uid6,  'anita.kapoor@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Anita Kapoor"}'::jsonb),
      (uid7,  'deepak.verma@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Deepak Verma"}'::jsonb),
      (uid8,  'kavita.singh@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Kavita Singh"}'::jsonb),
      (uid9,  'rohit.gupta@demo.in',      'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Rohit Gupta"}'::jsonb),
      (uid10, 'meena.agarwal@demo.in',    'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"vendor"}'::jsonb, '{"name":"Meena Agarwal"}'::jsonb);
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  -- Insert into public.users
  INSERT INTO public.users (id, email, name, role, avatar_url) VALUES
    (uid1,  'rahul.sharma@demo.in',  'Rahul Sharma',  'vendor', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80'),
    (uid2,  'priya.mehta@demo.in',   'Priya Mehta',   'vendor', 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150&q=80'),
    (uid3,  'arjun.patel@demo.in',   'Arjun Patel',   'vendor', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&q=80'),
    (uid4,  'sunita.desai@demo.in',  'Sunita Desai',  'vendor', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&q=80'),
    (uid5,  'vikram.joshi@demo.in',  'Vikram Joshi',  'vendor', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&q=80'),
    (uid6,  'anita.kapoor@demo.in',  'Anita Kapoor',  'vendor', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&q=80'),
    (uid7,  'deepak.verma@demo.in',  'Deepak Verma',  'vendor', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&q=80'),
    (uid8,  'kavita.singh@demo.in',  'Kavita Singh',  'vendor', 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150&q=80'),
    (uid9,  'rohit.gupta@demo.in',   'Rohit Gupta',   'vendor', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&q=80'),
    (uid10, 'meena.agarwal@demo.in', 'Meena Agarwal', 'vendor', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&q=80')
  ON CONFLICT (id) DO UPDATE SET
    role       = EXCLUDED.role,
    name       = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url;

  -- Clean up any previous seed run for idempotency
  DELETE FROM public.vendors
  WHERE user_id IN (uid1, uid2, uid3, uid4, uid5, uid6, uid7, uid8, uid9, uid10);

  -- Insert vendors
  INSERT INTO public.vendors (
    user_id, category, bio, tagline, city, base_price,
    is_verified, is_featured, rating_avg, events_count,
    years_experience, portfolio_urls, service_cities, phone, whatsapp
  ) VALUES
  (uid1, 'photographer',
    'Award-winning wedding photographer with 8 years of experience. Specializing in candid and traditional photography across Gujarat.',
    'Capturing your love story, one frame at a time',
    'Surat', 25000, true, true, 4.8, 120,
    8,
    ARRAY[
      'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=600&q=80',
      'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&q=80',
      'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=600&q=80',
      'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=600&q=80'
    ],
    ARRAY['Surat','Ahmedabad','Vadodara','Navsari'],
    '+919876543201', '+919876543201'),

  (uid2, 'makeup',
    'Celebrity makeup artist trained in Mumbai. Bridal makeup specialist using premium international brands. 200+ brides done.',
    'Glam up for your big day',
    'Ahmedabad', 15000, true, true, 4.9, 200,
    6,
    ARRAY[
      'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80',
      'https://images.unsplash.com/photo-1526413232644-8a40f03cc03b?w=600&q=80',
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80'
    ],
    ARRAY['Ahmedabad','Gandhinagar','Surat'],
    '+919876543202', '+919876543202'),

  (uid3, 'caterer',
    'Traditional Gujarati, Rajasthani and Pan-Indian catering with hygienic kitchen setup. Expert team of 50+ for events of 100–2000 guests.',
    'Sabka pet bhar ke raho',
    'Surat', 450, true, false, 4.5, 85,
    12,
    ARRAY[
      'https://images.unsplash.com/photo-1555244162-803834f70033?w=600&q=80',
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80',
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&q=80'
    ],
    ARRAY['Surat','Bharuch','Ankleshwar'],
    '+919876543203', '+919876543203'),

  (uid4, 'decorator',
    'Creative event decorator specializing in floral arrangements, LED lighting and themed decor for all occasions.',
    'Transforming spaces into magical venues',
    'Vadodara', 35000, false, true, 4.7, 95,
    7,
    ARRAY[
      'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=600&q=80',
      'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=600&q=80',
      'https://images.unsplash.com/photo-1478146059778-26028b07395a?w=600&q=80'
    ],
    ARRAY['Vadodara','Anand','Surat'],
    '+919876543204', '+919876543204'),

  (uid5, 'dj',
    'Professional DJ with 10 years of Bollywood, EDM and folk music experience. State-of-the-art sound and light setup for 500+ guests.',
    'Turn up the beats at your event',
    'Mumbai', 18000, true, false, 4.6, 300,
    10,
    ARRAY[
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
      'https://images.unsplash.com/photo-1571266028243-e4733b0f0bb0?w=600&q=80'
    ],
    ARRAY['Mumbai','Pune','Nashik'],
    '+919876543205', '+919876543205'),

  (uid6, 'mehendi',
    'Specialist in bridal and dulha mehendi. Expert in Arabic, Rajasthani and fusion designs with natural henna.',
    'Mehendi designs that tell your story',
    'Jaipur', 8000, true, false, 4.8, 180,
    5,
    ARRAY[
      'https://images.unsplash.com/photo-1527684651001-731c474bbb5a?w=600&q=80',
      'https://images.unsplash.com/photo-1611605645802-c21be743c321?w=600&q=80'
    ],
    ARRAY['Jaipur','Jodhpur','Ajmer'],
    '+919876543206', '+919876543206'),

  (uid7, 'videographer',
    'Cinematic wedding films that you will treasure forever. Drone footage, same-day edit, and 4K delivery.',
    'Your wedding film, Hollywood style',
    'Pune', 30000, true, true, 4.7, 75,
    6,
    ARRAY[
      'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=600&q=80',
      'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=600&q=80'
    ],
    ARRAY['Pune','Mumbai','Kolhapur'],
    '+919876543207', '+919876543207'),

  (uid8, 'pandit',
    'Vedic pandit with 20+ years experience. Expert in all Hindu rituals — wedding, housewarming, naming, thread ceremony.',
    'Sacred ceremonies performed with devotion',
    'Ahmedabad', 5000, false, false, 4.4, 500,
    20,
    ARRAY[
      'https://images.unsplash.com/photo-1605538032400-d8cfaf456b35?w=600&q=80'
    ],
    ARRAY['Ahmedabad','Gandhinagar','Anand'],
    '+919876543208', '+919876543208'),

  (uid9, 'florist',
    'Fresh floral arrangements for all events. Wholesale flowers sourced daily from flower market. Bulk orders at best rates.',
    'Flowers that speak your feelings',
    'Bangalore', 12000, false, false, 4.3, 60,
    4,
    ARRAY[
      'https://images.unsplash.com/photo-1487530811176-3780de880c2d?w=600&q=80',
      'https://images.unsplash.com/photo-1490750967868-88df5691cc61?w=600&q=80'
    ],
    ARRAY['Bangalore','Mysore'],
    '+919876543209', '+919876543209'),

  (uid10, 'photographer',
    'Pre-wedding specialist and portrait photographer. Natural light photographer. Travel shoots across Rajasthan forts.',
    'Pre-wedding stories worth telling',
    'Jaipur', 20000, true, false, 4.6, 90,
    5,
    ARRAY[
      'https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=600&q=80',
      'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=600&q=80',
      'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&q=80'
    ],
    ARRAY['Jaipur','Udaipur','Delhi'],
    '+919876543210', '+919876543210');

END $$;

-- ── 6. VENDOR PACKAGES ──────────────────────────────────────
INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
SELECT
  v.id,
  'Basic Wedding Package',
  25000,
  8,
  '["400 edited photos","Same-day highlights","Online gallery","Print album"]'::jsonb,
  'Wedding',
  true
FROM public.vendors v
JOIN public.users u ON u.id = v.user_id
WHERE u.email = 'rahul.sharma@demo.in'
ON CONFLICT DO NOTHING;

INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
SELECT
  v.id,
  'Premium Wedding Package',
  45000,
  12,
  '["800 edited photos","Drone footage","Same-day edit reel","2 albums","Engagement shoot included"]'::jsonb,
  'Wedding',
  true
FROM public.vendors v
JOIN public.users u ON u.id = v.user_id
WHERE u.email = 'rahul.sharma@demo.in'
ON CONFLICT DO NOTHING;

INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
SELECT
  v.id,
  'Birthday Special',
  12000,
  4,
  '["200 edited photos","Candid shots","Digital delivery in 3 days"]'::jsonb,
  'Birthday',
  true
FROM public.vendors v
JOIN public.users u ON u.id = v.user_id
WHERE u.email = 'rahul.sharma@demo.in'
ON CONFLICT DO NOTHING;

-- ── 7. MORE FAQS ─────────────────────────────────────────────
INSERT INTO public.faqs (category, question, answer, sort_order) VALUES
  ('Booking',  'What is the advance amount required?',
               'Most vendors require 30% advance to confirm booking. Balance is paid before or on event day.',
               10),
  ('Vendors',  'Can I visit vendor studio or office?',
               'Yes — tap the vendor profile, then "Contact" to get their address and schedule a meeting.',
               11),
  ('Platform', 'Is Jalaram Events available in my city?',
               'Currently live in 22+ cities across India. More cities being added every month.',
               12),
  ('Booking',  'What if I need to change the event date?',
               'Contact the vendor directly via chat. Rescheduling is subject to vendor availability.',
               13),
  ('Platform', 'Is there a mobile app?',
               'Yes — Jalaram Events app is available on Android and iOS.',
               14),
  ('Payments', 'Do you offer EMI options?',
               'Select vendors offer EMI via Razorpay Credit. Look for the EMI badge on vendor profiles.',
               15)
ON CONFLICT DO NOTHING;

-- ── 8. MORE COUPONS ──────────────────────────────────────────
INSERT INTO public.coupons (code, description, discount_type, discount_value, min_order, max_discount, is_active) VALUES
  ('DIWALI25',   'Diwali Special 25% off',        'percent', 25, 20000, 7500,  true),
  ('FLAT2000',   '₹2000 off orders above ₹50K',   'flat',  2000, 50000,  null, true),
  ('PHOTO15',    '15% off photography bookings',   'percent', 15, 12000, 3000,  true),
  ('FIRSTBOOK',  '₹500 off your first booking',    'flat',   500,  5000,  null, true)
ON CONFLICT (code) DO NOTHING;
