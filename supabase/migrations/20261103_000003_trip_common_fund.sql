-- SplitLui Phase 4: per-group common fund ledger.
-- Requires 20261103_000001_trip_groups.sql.
-- Run once in the Supabase SQL Editor. This migration is additive.

create table if not exists public.trip_fund_accounts (
  group_id uuid primary key references public.trip_groups(id) on delete cascade,
  balance numeric(18,2) not null default 0 check (balance >= 0),
  low_balance_threshold numeric(18,2) not null default 0
    check (low_balance_threshold >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.trip_fund_entries (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_fund_accounts(group_id)
    on delete cascade,
  entry_type text not null check (entry_type in ('contribution','expense')),
  amount numeric(18,2) not null check (amount > 0),
  member_id uuid references auth.users(id),
  description text not null check (char_length(btrim(description)) between 1 and 120),
  recorded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  check ((entry_type = 'contribution' and member_id is not null)
      or (entry_type = 'expense' and member_id is null))
);
create index if not exists trip_fund_entries_group_date_idx
  on public.trip_fund_entries(group_id, created_at desc);

alter table public.trip_fund_accounts enable row level security;
alter table public.trip_fund_entries enable row level security;
revoke all on public.trip_fund_accounts, public.trip_fund_entries from anon;
revoke all on public.trip_fund_accounts, public.trip_fund_entries from authenticated;
grant select on public.trip_fund_accounts, public.trip_fund_entries to authenticated;

drop policy if exists trip_fund_accounts_member_read
  on public.trip_fund_accounts;
create policy trip_fund_accounts_member_read on public.trip_fund_accounts
  for select to authenticated using (public.is_trip_member(group_id));

drop policy if exists trip_fund_entries_member_read
  on public.trip_fund_entries;
create policy trip_fund_entries_member_read on public.trip_fund_entries
  for select to authenticated using (public.is_trip_member(group_id));

-- Funds are ledgered in the group's spending currency only.
-- This RPC atomically locks the balance row for concurrent multi-device writes.
create or replace function public.record_trip_fund_entry(
  p_group uuid,
  p_type text,
  p_amount numeric,
  p_member uuid,
  p_description text
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  current_balance numeric(18,2);
  result_id uuid;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if p_type not in ('contribution','expense') or p_type is null then
    raise exception 'Invalid fund entry type';
  end if;
  if p_amount is null or p_amount <= 0
    or p_amount > 9999999999999999.99
    or p_amount != round(p_amount,2) then
    raise exception 'Amount must be positive with at most 2 decimals';
  end if;
  if p_description is null
    or char_length(btrim(p_description)) not between 1 and 120 then
    raise exception 'Description is required (1-120 characters)';
  end if;
  if p_type = 'contribution' then
    if p_member is null or not exists (
      select 1 from public.trip_members
      where group_id = p_group and user_id = p_member
    ) then
      raise exception 'Contributor must be a group member';
    end if;
  elsif p_member is not null then
    raise exception 'Fund expenses have no individual payer';
  end if;

  insert into public.trip_fund_accounts(group_id) values (p_group)
    on conflict (group_id) do nothing;
  select balance into current_balance from public.trip_fund_accounts
    where group_id = p_group for update;

  if p_type = 'expense' and current_balance < p_amount then
    raise exception 'Insufficient common fund balance';
  end if;

  update public.trip_fund_accounts set
    balance = case when p_type = 'contribution'
      then balance + p_amount else balance - p_amount end,
    updated_at = now()
    where group_id = p_group;

  insert into public.trip_fund_entries(
    group_id,entry_type,amount,member_id,description,recorded_by
  ) values (
    p_group,p_type,p_amount,
    case when p_type = 'contribution' then p_member else null end,
    btrim(p_description),auth.uid()
  ) returning id into result_id;

  return result_id;
end; $$;
revoke all on function public.record_trip_fund_entry(uuid,text,numeric,uuid,text)
  from public;
grant execute on function public.record_trip_fund_entry(uuid,text,numeric,uuid,text)
  to authenticated;

-- Threshold is optional; 0 means disabled. Only the group owner can edit it.
create or replace function public.set_trip_fund_threshold(
  p_group uuid, p_threshold numeric
)
returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = auth.uid() and role = 'owner'
  ) then
    raise exception 'Only the group owner can set the threshold';
  end if;
  if p_threshold is null or p_threshold < 0
    or p_threshold > 9999999999999999.99
    or p_threshold != round(p_threshold,2) then
    raise exception 'Invalid threshold';
  end if;
  insert into public.trip_fund_accounts(group_id,low_balance_threshold)
    values (p_group,p_threshold)
    on conflict (group_id) do update set
      low_balance_threshold = excluded.low_balance_threshold,
      updated_at = now();
end; $$;
revoke all on function public.set_trip_fund_threshold(uuid,numeric) from public;
grant execute on function public.set_trip_fund_threshold(uuid,numeric)
  to authenticated;

-- No direct INSERT/UPDATE/DELETE grants on either fund table.
-- Contributions are actual recorded payments, not promises.
-- Fund-paid expenses are NOT inserted into trip_expenses / trip_expense_shares.
-- Therefore the same expense is not allocated to members a second time.
