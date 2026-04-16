-- ============ SUPPORT TICKET MESSAGES ============

CREATE TABLE IF NOT EXISTS public.support_ticket_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id  UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body       TEXT NOT NULL,
  is_admin   BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS stm_ticket_created ON public.support_ticket_messages(ticket_id, created_at);

ALTER TABLE public.support_ticket_messages ENABLE ROW LEVEL SECURITY;

-- Owner or staff can read messages for their own tickets
CREATE POLICY "stm: participant read" ON public.support_ticket_messages FOR SELECT
  USING (
    ticket_id IN (SELECT id FROM public.support_tickets WHERE user_id = auth.uid())
    OR public.is_staff()
  );

-- Authenticated users can insert to their own tickets
CREATE POLICY "stm: participant insert" ON public.support_ticket_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND (
      ticket_id IN (SELECT id FROM public.support_tickets WHERE user_id = auth.uid())
      OR public.is_staff()
    )
  );

-- ============ VENDOR PACKAGES: add event_type column ============
ALTER TABLE public.vendor_packages
  ADD COLUMN IF NOT EXISTS event_type TEXT;

-- ============ RICH SAMPLE DATA WITH IMAGES ============

-- Update banners with real Unsplash image URLs
UPDATE public.banners SET image_url = 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=1200&q=80'
  WHERE title = 'Your Dream Wedding Awaits';
UPDATE public.banners SET image_url = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80'
  WHERE title = 'Corporate Events Made Easy';
UPDATE public.banners SET image_url = 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=1200&q=80'
  WHERE title = 'Birthday Celebrations';

-- Add more banners if missing
INSERT INTO public.banners (title, subtitle, image_url, sort_order) VALUES
  ('Capture Every Moment','Top photographers from ₹15,000','https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=1200&q=80', 4),
  ('Decorate Your Dream','Stunning decorations from ₹20,000','https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200&q=80', 5)
ON CONFLICT DO NOTHING;

-- Update FAQ for 2-language app
UPDATE public.faqs SET answer = 'Go to Profile → Settings → Language and pick Hindi or English.'
  WHERE question LIKE '%change my language%';

-- Add more FAQs
INSERT INTO public.faqs (category, question, answer, sort_order) VALUES
  ('Vendors','Can I compare vendors?','Yes — tap the compare icon on any vendor card to add up to 3 vendors, then view side-by-side.',6),
  ('Booking','How do I track my booking?','Go to Bookings tab → tap any booking to see status, timeline, and payment breakdown.',7),
  ('Payments','What payment methods are accepted?','UPI, debit/credit cards, net banking, and wallets — all via Razorpay.',8),
  ('Account','How do I refer a friend?','Go to Profile → Referral. Share your code and earn ₹200 when they complete their first booking.',9)
ON CONFLICT DO NOTHING;

-- Add checklist template for engagement
INSERT INTO public.checklist_templates (event_type, title, items) VALUES
  ('engagement','Engagement Checklist','["Book venue","Rings","Decorations","Photographer","Catering","Invitations","Mehendi artist","Music/DJ","Return gifts","Family coordination"]'::jsonb),
  ('anniversary','Anniversary Checklist','["Venue booking","Flowers & decorations","Special dinner","Photographer","Surprise gifts","Music arrangement","Guest list","Cake order"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Add sample vendors with Unsplash images (these require a real user_id so we use a subquery pattern)
-- Note: Run after at least one user has signed up. These are demo seeds.
-- They reference a placeholder vendor profile_views default.

-- Sample coupons
INSERT INTO public.coupons (code, description, discount_type, discount_value, min_order, max_discount) VALUES
  ('DIWALI20','20% off for Diwali season','percent',20,15000,5000),
  ('NEWVENDOR','₹1000 off for new vendors','flat',1000,8000,null),
  ('SUMMER15','15% summer discount','percent',15,12000,3000)
ON CONFLICT (code) DO NOTHING;
