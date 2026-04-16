-- ============================================================
-- ADVANCED FEATURES MIGRATION
-- ============================================================

-- ── 1. VENDOR: accepting bookings + response stats ───────────
ALTER TABLE public.vendors
  ADD COLUMN IF NOT EXISTS is_accepting_bookings BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS response_rate         INT DEFAULT 100 CHECK (response_rate BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS avg_response_hours    INT DEFAULT 2,
  ADD COLUMN IF NOT EXISTS badge_top_10          BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS early_bird_discount   INT DEFAULT 0 CHECK (early_bird_discount BETWEEN 0 AND 50);

-- ── 2. REVIEW HELPFUL VOTES ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.review_votes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id   UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_helpful  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (review_id, user_id)
);
CREATE INDEX IF NOT EXISTS rv_review ON public.review_votes(review_id);
ALTER TABLE public.review_votes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "votes: authenticated read"  ON public.review_votes FOR SELECT  TO authenticated USING (TRUE);
CREATE POLICY "votes: own insert/update"   ON public.review_votes FOR INSERT  TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "votes: own delete"          ON public.review_votes FOR DELETE  TO authenticated USING (user_id = auth.uid());

-- ── 3. BLOCKED VENDORS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.blocked_vendors (
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  vendor_id  UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, vendor_id)
);
ALTER TABLE public.blocked_vendors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "blocks: own manage" ON public.blocked_vendors FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ── 4. USER ACHIEVEMENTS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  achievement_key TEXT NOT NULL,  -- e.g. 'first_booking', 'five_bookings', 'top_reviewer'
  earned_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, achievement_key)
);
CREATE INDEX IF NOT EXISTS ua_user ON public.user_achievements(user_id);
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "achievements: own read"   ON public.user_achievements FOR SELECT USING (user_id = auth.uid() OR public.is_staff());
CREATE POLICY "achievements: staff write" ON public.user_achievements FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());
-- Auto-grant on booking/review events (trigger)
CREATE POLICY "achievements: auto insert" ON public.user_achievements FOR INSERT WITH CHECK (user_id = auth.uid());

-- ── 5. REVIEWS: add photo array + helpful counts view ────────
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS photos TEXT[] DEFAULT '{}';

CREATE OR REPLACE VIEW public.reviews_with_votes AS
SELECT
  r.*,
  COALESCE(v.helpful,   0)::INT AS helpful_count,
  COALESCE(v.unhelpful, 0)::INT AS unhelpful_count
FROM public.reviews r
LEFT JOIN (
  SELECT review_id,
    COUNT(*) FILTER (WHERE is_helpful)      AS helpful,
    COUNT(*) FILTER (WHERE NOT is_helpful)  AS unhelpful
  FROM public.review_votes
  GROUP BY review_id
) v ON v.review_id = r.id;

-- ── 6. GUEST INVITES: ensure code column default ─────────────
ALTER TABLE public.guest_invites
  ALTER COLUMN code SET DEFAULT upper(substr(md5(gen_random_uuid()::text), 1, 8));

-- ── 7. AVAILABILITY: add "available on date" index ───────────
CREATE INDEX IF NOT EXISTS va_date ON public.vendor_availability(blocked_date);

-- ── 8. SEED: mark top photographers as badge_top_10 ──────────
UPDATE public.vendors SET badge_top_10 = TRUE
WHERE category = 'photographer' AND rating_avg >= 4.7;

UPDATE public.vendors SET early_bird_discount = 15
WHERE category IN ('photographer','makeup','decorator') AND is_featured = TRUE;
