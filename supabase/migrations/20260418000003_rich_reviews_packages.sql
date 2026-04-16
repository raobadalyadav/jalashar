-- ============================================================
-- Rich reviews, packages, and video URLs for all seed vendors
-- ============================================================

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

  -- Seed client users
  cuid1 uuid := '22222222-0000-0000-0000-000000000001';
  cuid2 uuid := '22222222-0000-0000-0000-000000000002';
  cuid3 uuid := '22222222-0000-0000-0000-000000000003';
  cuid4 uuid := '22222222-0000-0000-0000-000000000004';
  cuid5 uuid := '22222222-0000-0000-0000-000000000005';
  cuid6 uuid := '22222222-0000-0000-0000-000000000006';

  vid1  uuid; vid2  uuid; vid3  uuid; vid4  uuid; vid5  uuid;
  vid6  uuid; vid7  uuid; vid8  uuid; vid9  uuid; vid10 uuid;

  -- Booking IDs for review FKs
  bid_1_1 uuid := gen_random_uuid();  bid_1_2 uuid := gen_random_uuid();
  bid_1_3 uuid := gen_random_uuid();  bid_1_4 uuid := gen_random_uuid();
  bid_1_5 uuid := gen_random_uuid();
  bid_2_1 uuid := gen_random_uuid();  bid_2_2 uuid := gen_random_uuid();
  bid_2_3 uuid := gen_random_uuid();  bid_2_4 uuid := gen_random_uuid();
  bid_2_5 uuid := gen_random_uuid();
  bid_3_1 uuid := gen_random_uuid();  bid_3_2 uuid := gen_random_uuid();
  bid_3_3 uuid := gen_random_uuid();  bid_3_4 uuid := gen_random_uuid();
  bid_3_5 uuid := gen_random_uuid();
  bid_4_1 uuid := gen_random_uuid();  bid_4_2 uuid := gen_random_uuid();
  bid_4_3 uuid := gen_random_uuid();  bid_4_4 uuid := gen_random_uuid();
  bid_4_5 uuid := gen_random_uuid();
  bid_5_1 uuid := gen_random_uuid();  bid_5_2 uuid := gen_random_uuid();
  bid_5_3 uuid := gen_random_uuid();  bid_5_4 uuid := gen_random_uuid();
  bid_5_5 uuid := gen_random_uuid();
  bid_6_1 uuid := gen_random_uuid();  bid_6_2 uuid := gen_random_uuid();
  bid_6_3 uuid := gen_random_uuid();  bid_6_4 uuid := gen_random_uuid();
  bid_6_5 uuid := gen_random_uuid();
  bid_7_1 uuid := gen_random_uuid();  bid_7_2 uuid := gen_random_uuid();
  bid_7_3 uuid := gen_random_uuid();  bid_7_4 uuid := gen_random_uuid();
  bid_7_5 uuid := gen_random_uuid();
  bid_8_1 uuid := gen_random_uuid();  bid_8_2 uuid := gen_random_uuid();
  bid_8_3 uuid := gen_random_uuid();  bid_8_4 uuid := gen_random_uuid();
  bid_9_1 uuid := gen_random_uuid();  bid_9_2 uuid := gen_random_uuid();
  bid_9_3 uuid := gen_random_uuid();  bid_9_4 uuid := gen_random_uuid();
  bid_10_1 uuid := gen_random_uuid(); bid_10_2 uuid := gen_random_uuid();
  bid_10_3 uuid := gen_random_uuid(); bid_10_4 uuid := gen_random_uuid();
  bid_10_5 uuid := gen_random_uuid();
BEGIN

  -- ── Seed client auth users ─────────────────────────────────
  BEGIN
    INSERT INTO auth.users (id, email, role, aud, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
    VALUES
      (cuid1, 'amit.shah@demo.in',     'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"client"}'::jsonb, '{"name":"Amit Shah"}'::jsonb),
      (cuid2, 'pooja.trivedi@demo.in', 'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"client"}'::jsonb, '{"name":"Pooja Trivedi"}'::jsonb),
      (cuid3, 'nikhil.rao@demo.in',    'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"client"}'::jsonb, '{"name":"Nikhil Rao"}'::jsonb),
      (cuid4, 'swati.jain@demo.in',    'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"client"}'::jsonb, '{"name":"Swati Jain"}'::jsonb),
      (cuid5, 'rajan.nair@demo.in',    'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"client"}'::jsonb, '{"name":"Rajan Nair"}'::jsonb),
      (cuid6, 'kavya.iyer@demo.in',    'authenticated', 'authenticated', extensions.crypt('Demo1234!', extensions.gen_salt('bf')), now(), now(), now(), '{"role":"client"}'::jsonb, '{"name":"Kavya Iyer"}'::jsonb);
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  INSERT INTO public.users (id, email, name, role) VALUES
    (cuid1, 'amit.shah@demo.in',     'Amit Shah',     'client'),
    (cuid2, 'pooja.trivedi@demo.in', 'Pooja Trivedi', 'client'),
    (cuid3, 'nikhil.rao@demo.in',    'Nikhil Rao',    'client'),
    (cuid4, 'swati.jain@demo.in',    'Swati Jain',    'client'),
    (cuid5, 'rajan.nair@demo.in',    'Rajan Nair',    'client'),
    (cuid6, 'kavya.iyer@demo.in',    'Kavya Iyer',    'client')
  ON CONFLICT (id) DO NOTHING;

  -- ── Fetch vendor IDs ───────────────────────────────────────
  SELECT id INTO vid1  FROM public.vendors WHERE user_id = uid1  LIMIT 1;
  SELECT id INTO vid2  FROM public.vendors WHERE user_id = uid2  LIMIT 1;
  SELECT id INTO vid3  FROM public.vendors WHERE user_id = uid3  LIMIT 1;
  SELECT id INTO vid4  FROM public.vendors WHERE user_id = uid4  LIMIT 1;
  SELECT id INTO vid5  FROM public.vendors WHERE user_id = uid5  LIMIT 1;
  SELECT id INTO vid6  FROM public.vendors WHERE user_id = uid6  LIMIT 1;
  SELECT id INTO vid7  FROM public.vendors WHERE user_id = uid7  LIMIT 1;
  SELECT id INTO vid8  FROM public.vendors WHERE user_id = uid8  LIMIT 1;
  SELECT id INTO vid9  FROM public.vendors WHERE user_id = uid9  LIMIT 1;
  SELECT id INTO vid10 FROM public.vendors WHERE user_id = uid10 LIMIT 1;

  -- ── Add video URLs to vendors ──────────────────────────────
  UPDATE public.vendors SET video_urls = ARRAY[
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://www.youtube.com/watch?v=9bZkp7q19f0'
  ] WHERE id = vid1;

  UPDATE public.vendors SET video_urls = ARRAY[
    'https://www.youtube.com/watch?v=kffacxfA7G4'
  ] WHERE id = vid2;

  UPDATE public.vendors SET video_urls = ARRAY[
    'https://www.youtube.com/watch?v=09R8_2nJtjg'
  ] WHERE id = vid7;

  UPDATE public.vendors SET video_urls = ARRAY[
    'https://www.youtube.com/watch?v=JGwWNGJdvx8'
  ] WHERE id = vid5;

  -- ── Packages for makeup artist (uid2) ─────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid2, 'Bridal Makeup Basic',   15000, 3, '["HD airbrush","Hairstyling","Draping assistance","Touch-up kit"]'::jsonb,                                   'Wedding',    true),
    (vid2, 'Bridal Makeup Premium', 25000, 5, '["HD airbrush","Designer saree draping","2 look changes","Hairstyle","Mehendi touch","Party makeup"]'::jsonb, 'Wedding',    true),
    (vid2, 'Party Glam',             5000, 2, '["Party makeup","Hair styling"]'::jsonb,                                                                      'Birthday',   true),
    (vid2, 'Engagement Glow',        9000, 3, '["Engagement makeup","Hair setting","Lip & eye accent"]'::jsonb,                                              'Engagement', true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for caterer (uid3) ───────────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid3, 'Budget Buffet (per plate)',   350, 6, '["Veg menu 15 items","Serving staff","Disposables included"]'::jsonb,           'Wedding',   true),
    (vid3, 'Premium Buffet (per plate)',  600, 8, '["Veg + non-veg 25 items","Live counters","Uniforms staff","Crockery"]'::jsonb, 'Wedding',   true),
    (vid3, 'Corporate Lunch (per plate)', 250, 4, '["Standard veg menu","Box packing available","Minimum 100 pax"]'::jsonb,        'Corporate', true),
    (vid3, 'Birthday Party Package',     8000, 4, '["Snacks + meal for 50 pax","Cake cutting setup","Soft drinks"]'::jsonb,        'Birthday',  true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for decorator (uid4) ─────────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid4, 'Basic Floral Decor',    20000,  8, '["Stage decoration","Entrance arch","Table centerpieces","Fairy lights"]'::jsonb,                            'Wedding',   true),
    (vid4, 'Grand Wedding Decor',   55000, 12, '["Full venue transformation","Floral canopy","LED backdrop","Phoolon ki chadar","Custom monogram"]'::jsonb,  'Wedding',   true),
    (vid4, 'Birthday Balloon Bash',  8000,  4, '["Balloon arch","Photo zone","Table decor","Thematic setup"]'::jsonb,                                        'Birthday',  true),
    (vid4, 'Corporate Stage Setup', 15000,  6, '["Stage backdrop","Podium","Table arrangement","Branding placement"]'::jsonb,                                'Corporate', true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for DJ (uid5) ────────────────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid5, 'DJ Starter',    12000,  4, '["2000W sound","Basic lighting","DJ controller","200 pax"]'::jsonb,               'Birthday',  true),
    (vid5, 'DJ Full Night', 18000,  8, '["4000W sound","LED moving heads","Fog machine","500 pax","MC service"]'::jsonb,  'Wedding',   true),
    (vid5, 'DJ Premium',    28000, 10, '["8000W JBL sound","Full LED truss","Laser lights","DJ + VJ","1000 pax"]'::jsonb, 'Wedding',   true),
    (vid5, 'Corporate DJ',  15000,  6, '["Clean playlist","Soft lighting","PA system","Presentations support"]'::jsonb,   'Corporate', true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for mehendi artist (uid6) ────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid6, 'Bridal Mehendi Full', 8000, 5, '["Both hands & feet full","Dulha mehendi basic","Natural henna"]'::jsonb,     'Wedding',    true),
    (vid6, 'Bridal + Party',     12000, 7, '["Bride full mehendi","5 ladies guest mehendi","Dulha hath"]'::jsonb,         'Wedding',    true),
    (vid6, 'Party Mehendi',       3000, 3, '["Up to 10 guests","Palm designs","Quick Arabic"]'::jsonb,                    'Birthday',   true),
    (vid6, 'Engagement Mehendi',  5000, 4, '["Bride hand mehendi","Arabic + Rajasthani mix","2 design choices"]'::jsonb, 'Engagement', true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for videographer (uid7) ──────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid7, 'Cinematic Wedding Film',  30000, 12, '["4K drone footage","3 min highlight reel","Full ceremony edit","Colour graded","USB delivery"]'::jsonb, 'Wedding',   true),
    (vid7, 'Wedding Highlights Only', 15000,  8, '["HD footage","5 min highlight","Next-day delivery"]'::jsonb,                                            'Wedding',   true),
    (vid7, 'Corporate Shoot',         12000,  6, '["Full coverage","Talking head interviews","Brand intro video"]'::jsonb,                                  'Corporate', true),
    (vid7, 'Birthday Reel',            8000,  4, '["60 second reel for Instagram","Fun edit","Music sync"]'::jsonb,                                         'Birthday',  true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for pandit (uid8) ────────────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid8, 'Wedding Ceremony (Saat Phere)', 5000, 4, '["Full Sanskrit mantras","Vedic rituals","Samagri included"]'::jsonb, 'Wedding',    true),
    (vid8, 'Griha Pravesh Puja',            2500, 2, '["Vastu puja","Navgraha","Samagri included"]'::jsonb,                'Festival',   true),
    (vid8, 'Satyanarayan Katha',            2000, 3, '["Full katha","Prasad arrangement","Pandit travel included"]'::jsonb,'Festival',   true),
    (vid8, 'Engagement Ceremony',           3000, 2, '["Sagai rituals","Ring exchange blessings"]'::jsonb,                 'Engagement', true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for florist (uid9) ───────────────────────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid9, 'Bridal Bouquet',         2000, 1, '["Custom bridal bouquet","Boutonniere for groom","Delivery included"]'::jsonb,         'Wedding',   true),
    (vid9, 'Full Venue Florals',    12000, 5, '["Stage flowers","Table centerpieces","Entrance garlands","Loose petals"]'::jsonb,     'Wedding',   true),
    (vid9, 'Birthday Flower Table',  3500, 2, '["Cake table arrangement","Photo zone flowers","Balloon accent"]'::jsonb,              'Birthday',  true),
    (vid9, 'Corporate Lobby Decor',  5000, 3, '["Reception desk flowers","Conference table","Daily fresh arrangement"]'::jsonb,       'Corporate', true)
  ON CONFLICT DO NOTHING;

  -- ── Packages for pre-wedding photographer (uid10) ─────────
  INSERT INTO public.vendor_packages (vendor_id, name, price, duration_hours, features, event_type, is_active)
  VALUES
    (vid10, 'Pre-Wedding Story',    20000, 6, '["300 edited photos","2 locations","Props included","Online gallery"]'::jsonb, 'Engagement', true),
    (vid10, 'Wedding Day Coverage', 22000, 8, '["500 edited photos","Candid + traditional","Digital delivery"]'::jsonb,      'Wedding',    true),
    (vid10, 'Fort Shoot (Jaipur)',  28000, 8, '["Amber Fort + Hawa Mahal","400 photos","Drone shot","Props"]'::jsonb,        'Engagement', true),
    (vid10, 'Birthday Portrait',     8000, 3, '["150 photos","Outdoor shoot","Same-day delivery"]'::jsonb,                   'Birthday',   true)
  ON CONFLICT DO NOTHING;

  -- ── Seed completed bookings (needed for review FKs) ───────
  INSERT INTO public.bookings (id, client_id, vendor_id, event_date, status, total_amount, advance_paid, created_at)
  VALUES
    -- vid1 bookings
    (bid_1_1, cuid1, vid1, now()-interval '70 days',  'completed', 25000, 7500,  now()-interval '80 days'),
    (bid_1_2, cuid2, vid1, now()-interval '30 days',  'completed', 25000, 7500,  now()-interval '40 days'),
    (bid_1_3, cuid3, vid1, now()-interval '45 days',  'completed', 25000, 7500,  now()-interval '55 days'),
    (bid_1_4, cuid4, vid1, now()-interval '60 days',  'completed', 45000, 13500, now()-interval '70 days'),
    (bid_1_5, cuid5, vid1, now()-interval '90 days',  'completed', 25000, 7500,  now()-interval '100 days'),
    -- vid2 bookings
    (bid_2_1, cuid1, vid2, now()-interval '20 days',  'completed', 15000, 4500,  now()-interval '30 days'),
    (bid_2_2, cuid3, vid2, now()-interval '35 days',  'completed', 25000, 7500,  now()-interval '45 days'),
    (bid_2_3, cuid4, vid2, now()-interval '42 days',  'completed', 15000, 4500,  now()-interval '52 days'),
    (bid_2_4, cuid5, vid2, now()-interval '60 days',  'completed', 25000, 7500,  now()-interval '70 days'),
    (bid_2_5, cuid6, vid2, now()-interval '75 days',  'completed', 15000, 4500,  now()-interval '85 days'),
    -- vid3 bookings
    (bid_3_1, cuid2, vid3, now()-interval '10 days',  'completed', 45000, 13500, now()-interval '20 days'),
    (bid_3_2, cuid3, vid3, now()-interval '38 days',  'completed', 30000, 9000,  now()-interval '48 days'),
    (bid_3_3, cuid4, vid3, now()-interval '50 days',  'completed', 45000, 13500, now()-interval '60 days'),
    (bid_3_4, cuid5, vid3, now()-interval '110 days', 'completed', 45000, 13500, now()-interval '120 days'),
    (bid_3_5, cuid6, vid3, now()-interval '65 days',  'completed', 30000, 9000,  now()-interval '75 days'),
    -- vid4 bookings
    (bid_4_1, cuid1, vid4, now()-interval '10 days',  'completed', 35000, 10500, now()-interval '20 days'),
    (bid_4_2, cuid2, vid4, now()-interval '24 days',  'completed', 55000, 16500, now()-interval '34 days'),
    (bid_4_3, cuid5, vid4, now()-interval '48 days',  'completed', 55000, 16500, now()-interval '58 days'),
    (bid_4_4, cuid6, vid4, now()-interval '70 days',  'completed', 8000,  2400,  now()-interval '80 days'),
    (bid_4_5, cuid3, vid4, now()-interval '90 days',  'completed', 35000, 10500, now()-interval '100 days'),
    -- vid5 bookings
    (bid_5_1, cuid2, vid5, now()-interval '15 days',  'completed', 18000, 5400,  now()-interval '25 days'),
    (bid_5_2, cuid3, vid5, now()-interval '32 days',  'completed', 28000, 8400,  now()-interval '42 days'),
    (bid_5_3, cuid4, vid5, now()-interval '45 days',  'completed', 18000, 5400,  now()-interval '55 days'),
    (bid_5_4, cuid1, vid5, now()-interval '65 days',  'completed', 28000, 8400,  now()-interval '75 days'),
    (bid_5_5, cuid6, vid5, now()-interval '100 days', 'completed', 15000, 4500,  now()-interval '110 days'),
    -- vid6 bookings
    (bid_6_1, cuid1, vid6, now()-interval '18 days',  'completed', 8000,  2400,  now()-interval '28 days'),
    (bid_6_2, cuid2, vid6, now()-interval '40 days',  'completed', 12000, 3600,  now()-interval '50 days'),
    (bid_6_3, cuid4, vid6, now()-interval '55 days',  'completed', 8000,  2400,  now()-interval '65 days'),
    (bid_6_4, cuid5, vid6, now()-interval '75 days',  'completed', 5000,  1500,  now()-interval '85 days'),
    (bid_6_5, cuid6, vid6, now()-interval '95 days',  'completed', 8000,  2400,  now()-interval '105 days'),
    -- vid7 bookings
    (bid_7_1, cuid3, vid7, now()-interval '19 days',  'completed', 30000, 9000,  now()-interval '29 days'),
    (bid_7_2, cuid4, vid7, now()-interval '41 days',  'completed', 30000, 9000,  now()-interval '51 days'),
    (bid_7_3, cuid5, vid7, now()-interval '58 days',  'completed', 15000, 4500,  now()-interval '68 days'),
    (bid_7_4, cuid6, vid7, now()-interval '80 days',  'completed', 30000, 9000,  now()-interval '90 days'),
    (bid_7_5, cuid1, vid7, now()-interval '115 days', 'completed', 30000, 9000,  now()-interval '125 days'),
    -- vid8 bookings
    (bid_8_1, cuid2, vid8, now()-interval '20 days',  'completed', 5000,  1500,  now()-interval '30 days'),
    (bid_8_2, cuid4, vid8, now()-interval '50 days',  'completed', 5000,  1500,  now()-interval '60 days'),
    (bid_8_3, cuid6, vid8, now()-interval '70 days',  'completed', 2000,  600,   now()-interval '80 days'),
    (bid_8_4, cuid1, vid8, now()-interval '100 days', 'completed', 5000,  1500,  now()-interval '110 days'),
    -- vid9 bookings
    (bid_9_1, cuid3, vid9, now()-interval '21 days',  'completed', 12000, 3600,  now()-interval '31 days'),
    (bid_9_2, cuid5, vid9, now()-interval '52 days',  'completed', 5000,  1500,  now()-interval '62 days'),
    (bid_9_3, cuid6, vid9, now()-interval '72 days',  'completed', 12000, 3600,  now()-interval '82 days'),
    (bid_9_4, cuid2, vid9, now()-interval '105 days', 'completed', 5000,  1500,  now()-interval '115 days'),
    -- vid10 bookings
    (bid_10_1, cuid4, vid10, now()-interval '16 days',  'completed', 20000, 6000, now()-interval '26 days'),
    (bid_10_2, cuid5, vid10, now()-interval '37 days',  'completed', 28000, 8400, now()-interval '47 days'),
    (bid_10_3, cuid6, vid10, now()-interval '49 days',  'completed', 20000, 6000, now()-interval '59 days'),
    (bid_10_4, cuid1, vid10, now()-interval '68 days',  'completed', 22000, 6600, now()-interval '78 days'),
    (bid_10_5, cuid2, vid10, now()-interval '90 days',  'completed', 28000, 8400, now()-interval '100 days')
  ON CONFLICT (id) DO NOTHING;

  -- ── Reviews (using comment field, linked to bookings above) ─

  -- Photographer uid1
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_1_1, vid1, cuid1, 5, 'Rahul captured every emotion of our wedding beautifully. The candid shots are priceless. Absolutely stunning work, highly recommend!',   now()-interval '5 days'),
    (bid_1_2, vid1, cuid2, 5, 'We were blown away by the quality. The album is something we will cherish forever. Very professional and punctual.',                    now()-interval '12 days'),
    (bid_1_3, vid1, cuid3, 4, 'Photos were excellent but delivery took slightly longer than promised. Overall very happy with the results.',                            now()-interval '20 days'),
    (bid_1_4, vid1, cuid4, 5, 'Rahul has an eye for detail that is rare. Every photo tells a story. Our family loved the candids especially!',                         now()-interval '35 days'),
    (bid_1_5, vid1, cuid5, 5, 'Amazing angles, great editing style. He made everyone feel comfortable. 100% worth the price.',                                         now()-interval '60 days')
  ON CONFLICT DO NOTHING;

  -- Makeup artist uid2
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_2_1, vid2, cuid1, 5, 'Priya''s bridal makeup was flawless. It lasted the entire day without a touch-up. She understood exactly what I wanted. Felt like a queen!',  now()-interval '4 days'),
    (bid_2_2, vid2, cuid3, 5, 'Best makeup I''ve ever had. The international brands she used felt amazing on skin. My photos came out so well. Celebrity-level glam!',        now()-interval '15 days'),
    (bid_2_3, vid2, cuid4, 5, 'I was nervous about heavy makeup but Priya gave me a natural bridal glow that was absolutely perfect. Very talented!',                        now()-interval '22 days'),
    (bid_2_4, vid2, cuid5, 4, 'Makeup quality was outstanding but she was 30 mins late. Still gave 4 stars because the results were incredible.',                           now()-interval '40 days'),
    (bid_2_5, vid2, cuid6, 5, 'She did makeup for 5 ladies at our wedding. Every single one looked beautiful. Very professional team. My entire family loved it!',           now()-interval '55 days')
  ON CONFLICT DO NOTHING;

  -- Caterer uid3
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_3_1, vid3, cuid2, 5, 'Arjun Caterers handled 400 guests at our wedding. Every item was hot, fresh and tasty. Zero complaints from guests!',       now()-interval '6 days'),
    (bid_3_2, vid3, cuid3, 4, 'The taste was great but the serving station layout could be improved. Overall good value for money.',                       now()-interval '18 days'),
    (bid_3_3, vid3, cuid4, 5, 'We have used them twice now. Consistent quality, amazing Gujarati thali. Staff was very well-behaved and helpful.',         now()-interval '30 days'),
    (bid_3_4, vid3, cuid5, 5, 'Six months later, guests still mention how delicious the food was at our wedding. Arjun is a master chef!',                now()-interval '90 days'),
    (bid_3_5, vid3, cuid6, 4, 'Very clean setup, hygienic food preparation. Slightly limited non-veg options but overall a great experience.',            now()-interval '45 days')
  ON CONFLICT DO NOTHING;

  -- Decorator uid4
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_4_1, vid4, cuid1, 5, 'Sunita transformed our hall beyond imagination. The floral arch and LED backdrop were breathtaking. Worth every rupee!',     now()-interval '3 days'),
    (bid_4_2, vid4, cuid2, 5, 'She listened to every little wish and made it come true. The phoolon ki chadar was absolutely gorgeous.',                   now()-interval '14 days'),
    (bid_4_3, vid4, cuid5, 4, 'Final cost was 10% over initial quote but the result was so stunning we didn''t mind. Very talented decorator.',            now()-interval '28 days'),
    (bid_4_4, vid4, cuid6, 5, 'Our daughter''s birthday looked like a movie set. Balloon arch, photo zone, everything was perfect. Kids loved it!',        now()-interval '50 days'),
    (bid_4_5, vid4, cuid3, 5, 'When I first saw the venue I literally cried. Sunita has an incredible eye for design. 10/10 recommend!',                   now()-interval '70 days')
  ON CONFLICT DO NOTHING;

  -- DJ uid5
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_5_1, vid5, cuid2, 5, 'Vikram read the crowd perfectly. From Bollywood to EDM to folk - everyone danced all night. Dance floor was never empty!', now()-interval '7 days'),
    (bid_5_2, vid5, cuid3, 5, 'Sound quality was top-notch. The lighting setup was professional. MC service was a great bonus. Will hire again!',         now()-interval '16 days'),
    (bid_5_3, vid5, cuid4, 4, 'Great playlist and energy. Sound was slightly too loud initially but adjusted on request. Overall very fun!',              now()-interval '25 days'),
    (bid_5_4, vid5, cuid1, 5, 'Vikram mixed our family''s favourite songs perfectly. Even the elders danced! That''s the mark of a great DJ.',            now()-interval '45 days'),
    (bid_5_5, vid5, cuid6, 5, 'Used Vikram for our office party. Clean playlist, professional setup. Employees loved it. Booking again next year.',       now()-interval '80 days')
  ON CONFLICT DO NOTHING;

  -- Mehendi uid6
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_6_1, vid6, cuid1, 5, 'Anita''s work is art. The bridal design on my hands and feet was intricate and perfectly executed. Lasted 10 days!',       now()-interval '8 days'),
    (bid_6_2, vid6, cuid2, 5, 'She sat for 4 hours and never rushed. Every curve and detail was perfect. My guests could not stop complimenting it.',     now()-interval '20 days'),
    (bid_6_3, vid6, cuid4, 5, 'Loved that she uses only natural henna. The colour was dark red and I had no allergies. Pure natural henna, no chemicals!',now()-interval '35 days'),
    (bid_6_4, vid6, cuid5, 4, 'Slightly expensive compared to local artists but the quality is miles ahead. Designs are unique and modern.',              now()-interval '55 days'),
    (bid_6_5, vid6, cuid6, 5, 'Came for engagement mehendi and fell in love with her Arabic fusion style. Quick, clean and beautiful.',                   now()-interval '75 days')
  ON CONFLICT DO NOTHING;

  -- Videographer uid7
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_7_1, vid7, cuid3, 5, 'Deepak''s cinematic editing captured the emotion of our day perfectly. The drone shots were stunning. Our wedding film made us cry!', now()-interval '9 days'),
    (bid_7_2, vid7, cuid4, 5, 'We could not believe this was shot at our wedding. The color grading, music sync and storytelling is incredible. Hollywood quality!', now()-interval '21 days'),
    (bid_7_3, vid7, cuid5, 4, 'The 3-min highlight reel was phenomenal. Full ceremony video was standard but highlight alone was worth the price.',                  now()-interval '38 days'),
    (bid_7_4, vid7, cuid6, 5, 'He delivered a 2-minute same-day edit at the reception itself. Guests were watching it on the projector. Absolutely genius!',         now()-interval '60 days'),
    (bid_7_5, vid7, cuid1, 5, 'The aerial shots of our venue looked like a movie. Deepak is truly in a league of his own. Booked him for a second event.',          now()-interval '95 days')
  ON CONFLICT DO NOTHING;

  -- Pandit uid8
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_8_1, vid8, cuid2, 5, 'Pandit Kavita Singh performed our Saat Phere with full Vedic mantras and explained each ritual. Very spiritual experience.',           now()-interval '10 days'),
    (bid_8_2, vid8, cuid4, 4, 'The ceremony was thorough but went 1 hour over time. Quality of rituals was excellent. Would recommend for traditional families.',     now()-interval '30 days'),
    (bid_8_3, vid8, cuid6, 5, 'Beautiful recitation, all samagri was provided. Very knowledgeable pandit. Our family was very pleased.',                              now()-interval '50 days'),
    (bid_8_4, vid8, cuid1, 4, 'Pandit ji knew every ritual deeply and performed them with devotion. Rates are slightly high but worth it for such events.',           now()-interval '80 days')
  ON CONFLICT DO NOTHING;

  -- Florist uid9
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_9_1, vid9, cuid3, 5, 'Rohit sources flowers daily from the market. Our venue fragrance was heavenly. Table centerpieces were showstoppers!',      now()-interval '11 days'),
    (bid_9_2, vid9, cuid5, 4, 'Fresh quality was excellent. Wished for more exotic flower options. Overall good service and timely delivery.',             now()-interval '32 days'),
    (bid_9_3, vid9, cuid6, 5, 'Exactly the colour scheme I wanted. He was very patient with my many revisions. Delivered on time. Highly recommend.',     now()-interval '52 days'),
    (bid_9_4, vid9, cuid2, 4, 'For the price, quality is good. Not the fanciest florist but reliable and fresh. Good for budget-conscious couples.',      now()-interval '85 days')
  ON CONFLICT DO NOTHING;

  -- Pre-wedding photographer uid10
  INSERT INTO public.reviews (booking_id, vendor_id, client_id, stars, comment, created_at) VALUES
    (bid_10_1, vid10, cuid4, 5, 'Meena took us to Amber Fort at golden hour. The photos look like magazine covers. Best pre-wedding investment ever!',              now()-interval '6 days'),
    (bid_10_2, vid10, cuid5, 5, 'She has a talent for making couples feel natural in front of the camera. No forced poses. Our personalities shine through.',        now()-interval '17 days'),
    (bid_10_3, vid10, cuid6, 5, 'Promised delivery in 2 weeks, delivered in 10 days. Edit quality is exceptional. Very responsive to feedback.',                    now()-interval '29 days'),
    (bid_10_4, vid10, cuid1, 4, 'Photography skills are top-notch. Props selection was a bit limited but made up for it with creativity. Happy overall.',           now()-interval '48 days'),
    (bid_10_5, vid10, cuid2, 5, 'The Rajasthan heritage series Meena created for us is hanging in our living room now. Absolute masterpiece!',                      now()-interval '70 days')
  ON CONFLICT DO NOTHING;

  -- ── Update rating averages to match seed reviews ──────────
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 125 WHERE id = vid1;
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 205 WHERE id = vid2;
  UPDATE public.vendors SET rating_avg = 4.6, events_count = 88  WHERE id = vid3;
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 98  WHERE id = vid4;
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 310 WHERE id = vid5;
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 185 WHERE id = vid6;
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 78  WHERE id = vid7;
  UPDATE public.vendors SET rating_avg = 4.5, events_count = 510 WHERE id = vid8;
  UPDATE public.vendors SET rating_avg = 4.5, events_count = 65  WHERE id = vid9;
  UPDATE public.vendors SET rating_avg = 4.8, events_count = 93  WHERE id = vid10;

END $$;
