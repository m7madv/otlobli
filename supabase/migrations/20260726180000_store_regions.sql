insert into public.app_settings (key, value)
values
  ('store_region_shein', '{"countryCode":"SA","currency":"USD","language":"ar","addressPath":["Riyadh Province","Riyadh","Al Olaya"]}'),
  ('store_region_temu', '{"countryCode":"SA","currency":"USD","language":"ar","addressPath":[]}')
on conflict (key) do nothing;
