insert into public.app_settings (key, value)
values
  ('brand_name', 'otlobli'),
  ('brand_logo_data_url', '')
on conflict (key) do nothing;
