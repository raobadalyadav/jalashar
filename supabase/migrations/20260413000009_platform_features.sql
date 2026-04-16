-- User suspension / ban
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_banned    BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ban_reason   TEXT;

-- Review photos
ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS photos TEXT[] DEFAULT '{}';

-- Vendor profile views time-series (simple append log)
CREATE TABLE IF NOT EXISTS vendor_view_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id  UUID REFERENCES vendors(id) ON DELETE CASCADE,
  viewed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_vendor_view_logs_vendor ON vendor_view_logs(vendor_id, viewed_at);

-- Search appearance log
CREATE TABLE IF NOT EXISTS vendor_search_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id  UUID REFERENCES vendors(id) ON DELETE CASCADE,
  searched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Guest invite links
CREATE TABLE IF NOT EXISTS guest_invites (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id  UUID REFERENCES bookings(id) ON DELETE CASCADE,
  host_id     UUID REFERENCES users(id),
  event_name  TEXT,
  event_date  DATE,
  venue       TEXT,
  message     TEXT,
  code        TEXT UNIQUE NOT NULL DEFAULT substr(md5(gen_random_uuid()::text), 1, 8),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for new tables
ALTER TABLE vendor_view_logs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_search_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_invites      ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can insert view log"
  ON vendor_view_logs FOR INSERT TO authenticated WITH CHECK (TRUE);
CREATE POLICY "Vendors see own view logs"
  ON vendor_view_logs FOR SELECT TO authenticated
  USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

CREATE POLICY "Anyone can insert search log"
  ON vendor_search_logs FOR INSERT TO authenticated WITH CHECK (TRUE);
CREATE POLICY "Vendors see own search logs"
  ON vendor_search_logs FOR SELECT TO authenticated
  USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

CREATE POLICY "Host manages own invites"
  ON guest_invites FOR ALL TO authenticated
  USING (host_id = auth.uid()) WITH CHECK (host_id = auth.uid());
CREATE POLICY "Anyone can read invite by code"
  ON guest_invites FOR SELECT TO authenticated USING (TRUE);

-- Function: 7-day and 30-day view counts
CREATE OR REPLACE FUNCTION get_vendor_view_stats(vendor_uuid UUID)
RETURNS TABLE(views_7d BIGINT, views_30d BIGINT) AS $$
  SELECT
    COUNT(*) FILTER (WHERE viewed_at >= NOW() - INTERVAL '7 days') AS views_7d,
    COUNT(*) FILTER (WHERE viewed_at >= NOW() - INTERVAL '30 days') AS views_30d
  FROM vendor_view_logs
  WHERE vendor_id = vendor_uuid;
$$ LANGUAGE SQL STABLE;
