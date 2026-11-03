-- Phase 18: private receipt attachment for personal and common-fund expenses.
-- Run after expense and common-fund migrations; create bucket in this migration.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('splitlui-receipts','splitlui-receipts',false,5242880,
        array['image/jpeg'])
on conflict (id) do update set public=false,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

create table if not exists public.trip_receipts (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  expense_id uuid references public.trip_expenses(id) on delete cascade,
  fund_entry_id uuid references public.trip_fund_entries(id) on delete cascade,
  object_path text not null unique,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint receipt_target_exactly_one check (
    (expense_id is not null) <> (fund_entry_id is not null)
  )
);
create unique index if not exists trip_receipts_expense_unique
  on public.trip_receipts(expense_id) where expense_id is not null;
create unique index if not exists trip_receipts_fund_unique
  on public.trip_receipts(fund_entry_id) where fund_entry_id is not null;
create index if not exists trip_receipts_group_idx
  on public.trip_receipts(group_id);
alter table public.trip_receipts enable row level security;
revoke all on public.trip_receipts from anon,authenticated;
grant select on public.trip_receipts to authenticated;
drop policy if exists trip_receipts_member_select on public.trip_receipts;
create policy trip_receipts_member_select on public.trip_receipts
for select to authenticated using (public.is_trip_member(group_id));

-- Every object must live under <group-id>/<uploader-id>/<random-id>.jpg.
-- All members can read group receipts. Only members may upload into their
-- own folder; the path must never make the bucket public.
drop policy if exists splitlui_receipt_member_read on storage.objects;
create policy splitlui_receipt_member_read on storage.objects
for select to authenticated using (
  bucket_id='splitlui-receipts'
  and (storage.foldername(name))[1] is not null
  and public.is_trip_member(((storage.foldername(name))[1])::uuid)
);
drop policy if exists splitlui_receipt_member_upload on storage.objects;
create policy splitlui_receipt_member_upload on storage.objects
for insert to authenticated with check (
  bucket_id='splitlui-receipts'
  and (storage.foldername(name))[1] is not null
  and (storage.foldername(name))[2] = auth.uid()::text
  and public.is_trip_member(((storage.foldername(name))[1])::uuid)
  and lower(storage.extension(name))='jpg'
);
drop policy if exists splitlui_receipt_uploader_delete on storage.objects;
create policy splitlui_receipt_uploader_delete on storage.objects
for delete to authenticated using (
  bucket_id='splitlui-receipts'
  and (storage.foldername(name))[2] = auth.uid()::text
  and public.is_trip_member(((storage.foldername(name))[1])::uuid)
  and not exists (select 1 from public.trip_receipts r
    where r.object_path = name)
);

-- The receipt can only be associated with an expense the current user
-- created / fund entry they recorded. Ensure the uploaded object exists.
create or replace function public.attach_trip_receipt(
  p_group uuid,p_expense uuid,p_fund_entry uuid,p_object_path text
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  new_id uuid;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if (p_expense is null) = (p_fund_entry is null) then
    raise exception 'Choose exactly one receipt target';
  end if;
  if p_object_path is null or
     p_object_path !~ ('^' || p_group::text || '/' ||
       auth.uid()::text || '/[0-9a-f-]{36}\.jpg$') then
    raise exception 'Invalid receipt upload path';
  end if;
  if not exists (select 1 from storage.objects
    where bucket_id='splitlui-receipts' and name=p_object_path) then
    raise exception 'Receipt image not uploaded';
  end if;
  if p_expense is not null and not exists (
    select 1 from public.trip_expenses
    where id=p_expense and group_id=p_group and created_by=auth.uid()
  ) then raise exception 'Not the expense author'; end if;
  if p_fund_entry is not null and not exists (
    select 1 from public.trip_fund_entries
    where id=p_fund_entry and group_id=p_group and recorded_by=auth.uid()
      and entry_type='expense'
  ) then raise exception 'Not the fund expense author'; end if;

  insert into public.trip_receipts(
    group_id,expense_id,fund_entry_id,object_path,created_by)
  values(p_group,p_expense,p_fund_entry,p_object_path,auth.uid())
  returning id into new_id;
  return new_id;
end; $$;
revoke all on function public.attach_trip_receipt(uuid,uuid,uuid,text) from public;
grant execute on function public.attach_trip_receipt(uuid,uuid,uuid,text)
to authenticated;
