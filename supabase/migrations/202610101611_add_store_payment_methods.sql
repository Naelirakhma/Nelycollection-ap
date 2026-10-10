alter table public.info_toko
  add column if not exists bri_account_number text not null default '',
  add column if not exists bri_account_name text not null default '',
  add column if not exists qris_image_url text not null default '';

update public.info_toko
set metode_bayar = 'BRI, Tunai, QRIS'
where metode_bayar is distinct from 'BRI, Tunai, QRIS';

notify pgrst, 'reload schema';
