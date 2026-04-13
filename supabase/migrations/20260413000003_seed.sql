-- Seed Jalaram service packages
insert into public.services (slug, name, description, base_price, planning_duration, features) values
('wedding', 'Royal Wedding', 'Complete wedding planning with premium vendors', 150000, '45-60 days',
  '["Venue selection","Decor & mandap","Photography & videography","Catering for 200+","Makeup & mehendi","DJ & sound","Priest & rituals","Guest management"]'::jsonb),
('engagement', 'Engagement Special', 'Elegant engagement ceremony planning', 60000, '20-30 days',
  '["Venue setup","Theme decor","Photography","Catering","DJ","Invitation design"]'::jsonb),
('birthday', 'Birthday Bash', 'Memorable birthday celebrations', 25000, '10-15 days',
  '["Theme decor","Cake & catering","Photography","Entertainment","Return gifts"]'::jsonb),
('corporate', 'Corporate Event', 'Professional corporate event management', 80000, '15-30 days',
  '["Venue booking","AV setup","Catering","Branding","Photography","Guest coordination"]'::jsonb),
('anniversary', 'Anniversary Celebration', 'Romantic anniversary planning', 40000, '15-20 days',
  '["Venue decor","Photography","Catering","Music","Surprise arrangements"]'::jsonb),
('festival', 'Festival Event', 'Traditional festival celebrations', 35000, '10-20 days',
  '["Decor","Catering","Priest","Cultural programs","Photography"]'::jsonb)
on conflict (slug) do nothing;
