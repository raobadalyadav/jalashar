-- Vendor meta (category-specific JSONB) + vendor_packages enhancements

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS meta JSONB DEFAULT '{}';

ALTER TABLE vendor_packages ADD COLUMN IF NOT EXISTS event_type TEXT;

ALTER TABLE vendor_packages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read vendor_packages"  ON vendor_packages;
DROP POLICY IF EXISTS "Vendor manages own packages"  ON vendor_packages;

CREATE POLICY "Public read vendor_packages"
  ON vendor_packages FOR SELECT USING (true);

CREATE POLICY "Vendor manages own packages"
  ON vendor_packages FOR ALL
  USING  (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()))
  WITH CHECK (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));
