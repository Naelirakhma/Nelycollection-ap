create or replace function public.nely_is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles as p
    where p.id = (select auth.uid())
      and p.role = 'admin'
  );
$$;

revoke all on function public.nely_is_admin() from public;
grant execute on function public.nely_is_admin() to anon, authenticated;

create or replace function public.nely_prevent_self_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role
     and (select auth.uid()) = old.id
     and not public.nely_is_admin() then
    raise exception 'Users cannot change their own role';
  end if;
  return new;
end;
$$;

drop trigger if exists nely_prevent_self_role_change on public.profiles;
create trigger nely_prevent_self_role_change
before update of role on public.profiles
for each row
execute function public.nely_prevent_self_role_change();

alter table public.profiles enable row level security;
revoke all on public.profiles from anon;
grant select, insert, update on public.profiles to authenticated;

drop policy if exists nely_profiles_read_self_or_admin on public.profiles;
create policy nely_profiles_read_self_or_admin
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or (select public.nely_is_admin())
);

drop policy if exists nely_profiles_read_guard on public.profiles;
create policy nely_profiles_read_guard
on public.profiles
as restrictive
for select
to authenticated
using (
  id = (select auth.uid())
  or (select public.nely_is_admin())
);

drop policy if exists nely_profiles_insert_self on public.profiles;
create policy nely_profiles_insert_self
on public.profiles
for insert
to authenticated
with check (
  (
    id = (select auth.uid())
    and role = 'customer'
  )
  or (select public.nely_is_admin())
);

drop policy if exists nely_profiles_insert_guard on public.profiles;
create policy nely_profiles_insert_guard
on public.profiles
as restrictive
for insert
to authenticated
with check (
  (
    id = (select auth.uid())
    and role = 'customer'
  )
  or (select public.nely_is_admin())
);

drop policy if exists nely_profiles_update_self_or_admin on public.profiles;
create policy nely_profiles_update_self_or_admin
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
  or (select public.nely_is_admin())
)
with check (
  id = (select auth.uid())
  or (select public.nely_is_admin())
);

drop policy if exists nely_profiles_update_guard on public.profiles;
create policy nely_profiles_update_guard
on public.profiles
as restrictive
for update
to authenticated
using (
  id = (select auth.uid())
  or (select public.nely_is_admin())
)
with check (
  id = (select auth.uid())
  or (select public.nely_is_admin())
);

grant select on public.jasa_jahit, public.kebaya, public.galeri, public.info_toko
to anon, authenticated;
grant insert, update, delete
on public.jasa_jahit, public.kebaya, public.galeri
to authenticated;
grant update on public.info_toko to authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array['jasa_jahit', 'kebaya', 'galeri'] loop
    execute format('alter table public.%I enable row level security', table_name);

    execute format('drop policy if exists nely_catalog_read on public.%I', table_name);
    execute format(
      'create policy nely_catalog_read on public.%I for select to anon, authenticated using (true)',
      table_name
    );

    execute format('drop policy if exists nely_catalog_admin_insert on public.%I', table_name);
    execute format(
      'create policy nely_catalog_admin_insert on public.%I for insert to authenticated with check ((select public.nely_is_admin()))',
      table_name
    );
    execute format('drop policy if exists nely_catalog_admin_update on public.%I', table_name);
    execute format(
      'create policy nely_catalog_admin_update on public.%I for update to authenticated using ((select public.nely_is_admin())) with check ((select public.nely_is_admin()))',
      table_name
    );
    execute format('drop policy if exists nely_catalog_admin_delete on public.%I', table_name);
    execute format(
      'create policy nely_catalog_admin_delete on public.%I for delete to authenticated using ((select public.nely_is_admin()))',
      table_name
    );

    execute format('drop policy if exists nely_catalog_insert_guard on public.%I', table_name);
    execute format(
      'create policy nely_catalog_insert_guard on public.%I as restrictive for insert to public with check ((select public.nely_is_admin()))',
      table_name
    );
    execute format('drop policy if exists nely_catalog_update_guard on public.%I', table_name);
    execute format(
      'create policy nely_catalog_update_guard on public.%I as restrictive for update to public using ((select public.nely_is_admin())) with check ((select public.nely_is_admin()))',
      table_name
    );
    execute format('drop policy if exists nely_catalog_delete_guard on public.%I', table_name);
    execute format(
      'create policy nely_catalog_delete_guard on public.%I as restrictive for delete to public using ((select public.nely_is_admin()))',
      table_name
    );
  end loop;
end
$$;

alter table public.info_toko enable row level security;
drop policy if exists nely_shop_info_read on public.info_toko;
create policy nely_shop_info_read
on public.info_toko
for select
to anon, authenticated
using (true);

drop policy if exists nely_shop_info_admin_update on public.info_toko;
create policy nely_shop_info_admin_update
on public.info_toko
for update
to authenticated
using ((select public.nely_is_admin()))
with check ((select public.nely_is_admin()));

drop policy if exists nely_shop_info_update_guard on public.info_toko;
create policy nely_shop_info_update_guard
on public.info_toko
as restrictive
for update
to public
using ((select public.nely_is_admin()))
with check ((select public.nely_is_admin()));

grant select, insert, update, delete on public.pesanan to authenticated;
alter table public.pesanan enable row level security;

drop policy if exists nely_orders_read_own_or_admin on public.pesanan;
create policy nely_orders_read_own_or_admin
on public.pesanan
for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select public.nely_is_admin())
);

drop policy if exists nely_orders_insert_own_or_admin on public.pesanan;
create policy nely_orders_insert_own_or_admin
on public.pesanan
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  or (select public.nely_is_admin())
);

drop policy if exists nely_orders_update_own_or_admin on public.pesanan;
create policy nely_orders_update_own_or_admin
on public.pesanan
for update
to authenticated
using (
  user_id = (select auth.uid())
  or (select public.nely_is_admin())
)
with check (
  user_id = (select auth.uid())
  or (select public.nely_is_admin())
);

drop policy if exists nely_orders_admin_delete on public.pesanan;
create policy nely_orders_admin_delete
on public.pesanan
for delete
to authenticated
using ((select public.nely_is_admin()));

drop policy if exists nely_orders_write_guard on public.pesanan;
create policy nely_orders_write_guard
on public.pesanan
as restrictive
for all
to public
using (
  (select auth.uid()) is not null
  and (
    user_id = (select auth.uid())
    or (select public.nely_is_admin())
  )
)
with check (
  (select auth.uid()) is not null
  and (
    user_id = (select auth.uid())
    or (select public.nely_is_admin())
  )
);

create or replace function public.nely_validate_customer_order_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.nely_is_admin() then
    return new;
  end if;

  if (select auth.uid()) is null or new.user_id <> (select auth.uid()) then
    raise exception 'Customers can only write their own orders';
  end if;

  if tg_op = 'INSERT' then
    if new.total is distinct from 0
       or new.dp is distinct from 0
       or new.proses is distinct from 0
       or new.status_bayar is distinct from 'Belum Bayar' then
      raise exception 'New customer orders must start in the pending state';
    end if;
    return new;
  end if;

  if new.id is distinct from old.id
     or new.user_id is distinct from old.user_id
     or new.customer_nama is distinct from old.customer_nama
     or new.customer_wa is distinct from old.customer_wa
     or new.jenis is distinct from old.jenis
     or new.item_nama is distinct from old.item_nama
     or new.detail is distinct from old.detail
     or new.ukuran is distinct from old.ukuran
     or new.tanggal_butuh is distinct from old.tanggal_butuh
     or new.tanggal_sewa is distinct from old.tanggal_sewa
     or new.tanggal_kembali is distinct from old.tanggal_kembali
     or new.total is distinct from old.total
     or new.dp is distinct from old.dp
     or new.created_at is distinct from old.created_at then
    raise exception 'Customers cannot change protected order details';
  end if;

  if new.proses is distinct from old.proses
     and old.proses = 0
     and new.proses = 1
     and old.total > 0
     and new.status_bayar is not distinct from old.status_bayar
     and new.metode_bayar is not distinct from old.metode_bayar then
    return new;
  end if;

  if new.proses is not distinct from old.proses
     and old.proses >= 1
     and old.total > 0
     and old.status_bayar in ('Belum Bayar', 'Ditolak')
     and new.metode_bayar in ('QRIS', 'Transfer', 'Tunai')
     and (
       (new.metode_bayar = 'Tunai' and new.status_bayar = 'Belum Bayar')
       or (
         new.metode_bayar in ('QRIS', 'Transfer')
         and new.status_bayar = 'Menunggu Verifikasi'
       )
     ) then
    return new;
  end if;

  raise exception 'Customer order update is not allowed';
end;
$$;

drop trigger if exists nely_validate_customer_order_write on public.pesanan;
create trigger nely_validate_customer_order_write
before insert or update on public.pesanan
for each row
execute function public.nely_validate_customer_order_write();

notify pgrst, 'reload schema';
