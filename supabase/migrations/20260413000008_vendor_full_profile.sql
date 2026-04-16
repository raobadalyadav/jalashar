-- Full vendor profile fields, reports table, image messages, analytics

-- ── Vendors extended profile ───────────────────────────────────────────────
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS whatsapp TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS years_experience INTEGER DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS events_count INTEGER DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS service_cities TEXT[] DEFAULT '{}';
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS languages TEXT[] DEFAULT '{}';
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS instagram_url TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS youtube_url TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS facebook_url TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS tagline TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS max_events_per_day INTEGER DEFAULT 1;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS fully_booked BOOLEAN DEFAULT FALSE;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS profile_views INTEGER DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS search_appearances INTEGER DEFAULT 0;

-- ── messages: image support ────────────────────────────────────────────────
ALTER TABLE messages ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ── bookings: event_type ──────────────────────────────────────────────────
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS event_type TEXT;

-- ── reports ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can report vendors" ON reports;
CREATE POLICY "Users can report vendors"
  ON reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS "Users see own reports" ON reports;
CREATE POLICY "Users see own reports"
  ON reports FOR SELECT
  USING (reporter_id = auth.uid());

-- ── Function: increment profile views (called from app) ───────────────────
CREATE OR REPLACE FUNCTION increment_profile_views(vendor_uuid UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE vendors SET profile_views = profile_views + 1 WHERE id = vendor_uuid;
END $$;

-- ── Function: recalculate rating_avg after review insert ──────────────────
CREATE OR REPLACE FUNCTION update_vendor_rating()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE vendors
  SET rating_avg = (
    SELECT COALESCE(AVG(stars::NUMERIC), 0)
    FROM reviews
    WHERE vendor_id = NEW.vendor_id
  ),
  events_count = (
    SELECT COUNT(*) FROM bookings
    WHERE vendor_id = NEW.vendor_id
    AND status = 'completed'
  )
  WHERE id = NEW.vendor_id;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS on_review_insert ON reviews;
CREATE TRIGGER on_review_insert
  AFTER INSERT ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_vendor_rating();
