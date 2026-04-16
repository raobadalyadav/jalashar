-- ============================================================
-- Missing features migration
-- ============================================================

-- 1. Video reels on vendors
ALTER TABLE public.vendors
  ADD COLUMN IF NOT EXISTS video_urls      text[]    DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS acceptance_hours int       DEFAULT NULL,  -- auto-decline after X hours
  ADD COLUMN IF NOT EXISTS quick_replies    text[]    DEFAULT '{}';  -- vendor's own quick reply templates

-- 2. Review verified-booking badge
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS is_verified_booking boolean NOT NULL DEFAULT false;

-- 3. Helpful count denormalized on reviews for fast display
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS helpful_count   int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS unhelpful_count int NOT NULL DEFAULT 0;

-- Function to keep helpful_count synced when votes change
CREATE OR REPLACE FUNCTION public.sync_review_votes()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.reviews SET
    helpful_count   = (SELECT count(*) FROM public.review_votes WHERE review_id = COALESCE(NEW.review_id, OLD.review_id) AND is_helpful = true),
    unhelpful_count = (SELECT count(*) FROM public.review_votes WHERE review_id = COALESCE(NEW.review_id, OLD.review_id) AND is_helpful = false)
  WHERE id = COALESCE(NEW.review_id, OLD.review_id);
  RETURN COALESCE(NEW, OLD);
END $$;

DROP TRIGGER IF EXISTS trg_sync_review_votes ON public.review_votes;
CREATE TRIGGER trg_sync_review_votes
  AFTER INSERT OR UPDATE OR DELETE ON public.review_votes
  FOR EACH ROW EXECUTE FUNCTION public.sync_review_votes();

-- 4. Mark review as verified if booking exists
CREATE OR REPLACE FUNCTION public.mark_review_verified()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.booking_id IS NOT NULL THEN
    NEW.is_verified_booking := EXISTS (
      SELECT 1 FROM public.bookings
      WHERE id = NEW.booking_id AND client_id = NEW.client_id AND status IN ('completed','confirmed')
    );
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_mark_review_verified ON public.reviews;
CREATE TRIGGER trg_mark_review_verified
  BEFORE INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.mark_review_verified();

-- 5. Quick reply templates table (global platform defaults, vendors can add their own)
CREATE TABLE IF NOT EXISTS public.quick_reply_templates (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id   uuid REFERENCES public.vendors(id) ON DELETE CASCADE,  -- NULL = global
  body        text NOT NULL,
  sort_order  int  NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.quick_reply_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vendors_manage_own_quick_replies" ON public.quick_reply_templates
  FOR ALL USING (
    vendor_id IS NULL OR
    vendor_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
  );

-- Seed global quick replies
INSERT INTO public.quick_reply_templates (vendor_id, body, sort_order) VALUES
  (NULL, 'Thank you! I''ll confirm your booking shortly.', 1),
  (NULL, 'I''m available on that date. Please share event details.', 2),
  (NULL, 'Please call me to discuss details.', 3),
  (NULL, 'I''ll contact you 2 days before the event.', 4),
  (NULL, 'Could you share more details about your event?', 5),
  (NULL, 'Payment is to be settled directly on or before the event.', 6),
  (NULL, 'Thank you for choosing me! Looking forward to your event.', 7),
  (NULL, 'Unfortunately that date is not available. Can we check an alternate date?', 8)
ON CONFLICT DO NOTHING;

-- 6. Star breakdown view (for fast display on vendor profile)
CREATE OR REPLACE VIEW public.vendor_star_breakdown AS
SELECT
  vendor_id,
  count(*) FILTER (WHERE stars = 5) AS five_star,
  count(*) FILTER (WHERE stars = 4) AS four_star,
  count(*) FILTER (WHERE stars = 3) AS three_star,
  count(*) FILTER (WHERE stars = 2) AS two_star,
  count(*) FILTER (WHERE stars = 1) AS one_star,
  count(*) AS total
FROM public.reviews
GROUP BY vendor_id;

-- 7. Profile completion helper function
CREATE OR REPLACE FUNCTION public.vendor_completion_pct(vendor_id uuid)
RETURNS int LANGUAGE plpgsql STABLE AS $$
DECLARE
  v public.vendors;
  score int := 0;
BEGIN
  SELECT * INTO v FROM public.vendors WHERE id = vendor_id;
  IF NOT FOUND THEN RETURN 0; END IF;
  IF v.name IS NOT NULL AND v.name != '' THEN score := score + 10; END IF;
  IF v.bio IS NOT NULL AND v.bio != '' THEN score := score + 10; END IF;
  IF v.phone IS NOT NULL THEN score := score + 10; END IF;
  IF v.city IS NOT NULL THEN score := score + 10; END IF;
  IF cardinality(v.portfolio_urls) > 0 THEN score := score + 10; END IF;
  IF cardinality(v.service_cities) > 0 THEN score := score + 10; END IF;
  IF v.tagline IS NOT NULL AND v.tagline != '' THEN score := score + 10; END IF;
  IF v.instagram_url IS NOT NULL OR v.youtube_url IS NOT NULL THEN score := score + 10; END IF;
  IF cardinality(v.video_urls) > 0 THEN score := score + 10; END IF;
  IF v.years_experience IS NOT NULL THEN score := score + 10; END IF;
  RETURN score;
END $$;

-- 8. RLS on vendor_star_breakdown view
ALTER VIEW public.vendor_star_breakdown OWNER TO postgres;
