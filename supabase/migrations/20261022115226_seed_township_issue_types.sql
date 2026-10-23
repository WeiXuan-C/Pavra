-- Starter categories for township operations. They remain editable in the app.
insert into public.issue_types (name, slug, category, description, is_active, sort_order)
values
  ('Pothole', 'pothole', 'road', 'Holes or surface failures on a road', true, 10),
  ('Road crack', 'road-crack', 'road', 'Cracks or fissures in a road surface', true, 20),
  ('Drainage', 'drainage', 'drainage', 'Blocked, damaged, or overflowing drains', true, 30),
  ('Flooding', 'flooding', 'drainage', 'Water accumulation or flood risk', true, 40),
  ('Streetlight', 'streetlight', 'public-lighting', 'Faulty, damaged, or missing streetlights', true, 50),
  ('Sidewalk', 'sidewalk', 'pedestrian', 'Damaged or inaccessible pedestrian paths', true, 60),
  ('Traffic sign', 'traffic-sign', 'road-safety', 'Damaged, missing, or obscured signage', true, 70),
  ('Illegal dumping', 'illegal-dumping', 'waste', 'Waste dumped outside authorised collection points', true, 80),
  ('Playground', 'playground', 'public-facility', 'Unsafe or damaged playground equipment', true, 90),
  ('Fallen tree', 'fallen-tree', 'public-safety', 'Fallen or hazardous trees and branches', true, 100),
  ('Obstruction', 'obstruction', 'public-safety', 'Physical obstruction affecting public access', true, 110),
  ('Other public infrastructure', 'other-public-infrastructure', 'other', 'Other township infrastructure issue', true, 999)
on conflict (name) do update set
  slug = excluded.slug,
  category = excluded.category,
  description = excluded.description,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  updated_at = now();
