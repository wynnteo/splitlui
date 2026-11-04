-- Phase 3: targets, top-up requests and confirmed refunds.
-- Apply AFTER 20261103_000016_fund_expense_corrections.sql.
-- All accounting amounts are in the group's SPENDING currency.
-- Promises/requests never move money. Only confirmed entries change balance.

create table if not exists public.trip_fund_targets (
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  member_id uuid not null references auth.users(id),
  target_amount numeric(18,2) not null check (target_amount >= 0),
  updated_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (group_id,member_id)
);

create table if not exists public.trip_fund_topup_requests (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  member_id uuid not null references auth.users(id),
  requested_amount numeric(18,2) not null check (requested_amount > 0),
  note text not null default '',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  check (char_length(note) <= 120)
);
create index if not exists fund_requests_group_date
  on public.trip_fund_topup_requests(group_id,created_at desc);

create table if not exists public.trip_fund_refunds (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  member_id uuid not null references auth.users(id),
  amount numeric(18,2) not null check (amount > 0),
  client_operation_id uuid not null unique,
  note text not null check (char_length(btrim(note)) between 3 and 120),
  confirmed_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists fund_refunds_group_date
  on public.trip_fund_refunds(group_id,created_at desc);

alter table public.trip_fund_targets enable row level security;
alter table public.trip_fund_topup_requests enable row level security;
alter table public.trip_fund_refunds enable row level security;
revoke all on public.trip_fund_targets,public.trip_fund_topup_requests,
  public.trip_fund_refunds from public,anon,authenticated;
grant select on public.trip_fund_targets,public.trip_fund_topup_requests,
  public.trip_fund_refunds to authenticated;

drop policy if exists fund_target_member_read on public.trip_fund_targets;
create policy fund_target_member_read on public.trip_fund_targets
  for select to authenticated using (public.is_trip_member(group_id));
drop policy if exists fund_topup_member_read on public.trip_fund_topup_requests;
create policy fund_topup_member_read on public.trip_fund_topup_requests
  for select to authenticated using (public.is_trip_member(group_id));
drop policy if exists fund_refund_member_read on public.trip_fund_refunds;
create policy fund_refund_member_read on public.trip_fund_refunds
  for select to authenticated using (public.is_trip_member(group_id));

-- Admin-only target changes, including zero to clear target.
create or replace function public.set_trip_fund_target(
  p_group uuid,p_member uuid,p_target numeric
) returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or not exists(
    select 1 from public.trip_members where group_id=p_group
      and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only the group owner may set targets'; end if;
  if not exists(select 1 from public.trip_members
    where group_id=p_group and user_id=p_member) then
    raise exception 'Member no longer belongs to group';
  end if;
  if p_target is null or p_target < 0 or p_target > 99999999999999.99
     or p_target != round(p_target,2) then
    raise exception 'Invalid target';
  end if;
  insert into public.trip_fund_targets(
    group_id,member_id,target_amount,updated_by)
  values(p_group,p_member,p_target,auth.uid())
  on conflict(group_id,member_id) do update
  set target_amount=excluded.target_amount,
      updated_by=excluded.updated_by,updated_at=clock_timestamp();
end; $$;
revoke all on function public.set_trip_fund_target(uuid,uuid,numeric) from public;
grant execute on function public.set_trip_fund_target(uuid,uuid,numeric)
  to authenticated;

-- Requests are communication, not incoming funds. Owner can cancel one.
-- Clean up an accidentally created five-argument version from an earlier
-- failed SQL Editor run (if the editor committed preceding statements).
drop function if exists public.request_trip_fund_topup(uuid,uuid,numeric,text,uuid);
create or replace function public.request_trip_fund_topup(
  p_group uuid,p_member uuid,p_amount numeric,p_note text
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare new_id uuid;
begin
  if auth.uid() is null or not exists(
    select 1 from public.trip_members where group_id=p_group
      and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only the group owner may request a top-up'; end if;
  if not exists(select 1 from public.trip_members
    where group_id=p_group and user_id=p_member) then
    raise exception 'Member no longer belongs to group';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 99999999999999.99
    or p_amount != round(p_amount,2) then
    raise exception 'Invalid requested amount';
  end if;
  if char_length(coalesce(p_note,'')) > 120 then
    raise exception 'Note too long';
  end if;
  insert into public.trip_fund_topup_requests(
    group_id,member_id,requested_amount,note,created_by)
  values(p_group,p_member,p_amount,coalesce(btrim(p_note),''),auth.uid())
  returning id into new_id;
  return new_id;
end; $$;
revoke all on function public.request_trip_fund_topup(uuid,uuid,numeric,text)
  from public;
grant execute on function public.request_trip_fund_topup(uuid,uuid,numeric,text)
  to authenticated;

create or replace function public.cancel_trip_fund_topup(
  p_group uuid,p_request uuid
) returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or not exists(
    select 1 from public.trip_members where group_id=p_group
      and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only owner may cancel a request'; end if;
  update public.trip_fund_topup_requests
  set cancelled_at=clock_timestamp(),cancelled_by=auth.uid()
  where id=p_request and group_id=p_group and cancelled_at is null;
  if not found then raise exception 'Request not found or already cancelled'; end if;
end; $$;
revoke all on function public.cancel_trip_fund_topup(uuid,uuid) from public;
grant execute on function public.cancel_trip_fund_topup(uuid,uuid)
  to authenticated;

-- Confirm a refund ONLY after money was physically handed to the recipient.
-- Lock the existing fund account row to serialize concurrent debit operations.
-- Prevent refunding more than the member's actual net contributions.
create or replace function public.confirm_trip_fund_refund(
  p_group uuid,p_member uuid,p_amount numeric,p_note text,p_operation uuid
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  balance_now numeric(18,2);
  contributed numeric(18,2);
  already_refunded numeric(18,2);
  result_id uuid;
  prior public.trip_fund_refunds%rowtype;
begin
  if auth.uid() is null or not exists(
    select 1 from public.trip_members where group_id=p_group
      and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only the group owner may confirm refunds'; end if;
  if not exists(select 1 from public.trip_members
    where group_id=p_group and user_id=p_member) then
    raise exception 'Refund recipient is not a group member';
  end if;
  if p_operation is null then raise exception 'Operation ID required'; end if;
  if p_amount is null or p_amount <= 0 or p_amount > 99999999999999.99
    or p_amount != round(p_amount,2) then
    raise exception 'Invalid refund amount';
  end if;
  if p_note is null or char_length(btrim(p_note)) not between 3 and 120 then
    raise exception 'Describe how/why the refund was received';
  end if;
  select balance into balance_now from public.trip_fund_accounts
    where group_id=p_group for update;
  if not found then raise exception 'Fund account not found'; end if;
  select * into prior from public.trip_fund_refunds
    where client_operation_id=p_operation;
  if found then
    if prior.group_id != p_group or prior.member_id != p_member
       or prior.amount != p_amount or prior.note != btrim(p_note)
       or prior.confirmed_by != auth.uid() then
      raise exception 'Refund operation ID reused with different data';
    end if;
    return prior.id;
  end if;
  if balance_now < p_amount then raise exception 'Insufficient fund balance'; end if;

  select coalesce(sum(amount),0) into contributed
  from public.trip_fund_entries
  where group_id=p_group and entry_type='contribution' and member_id=p_member;
  select coalesce(sum(amount),0) into already_refunded
  from public.trip_fund_refunds
  where group_id=p_group and member_id=p_member;
  if contributed - already_refunded < p_amount then
    raise exception 'Refund exceeds recorded net contributions';
  end if;
  update public.trip_fund_accounts set
    balance=balance-p_amount,updated_at=clock_timestamp()
  where group_id=p_group;
  insert into public.trip_fund_refunds(
    group_id,member_id,amount,note,confirmed_by,client_operation_id)
  values(p_group,p_member,p_amount,btrim(p_note),auth.uid(),p_operation)
  returning id into result_id;
  return result_id;
end; $$;
revoke all on function public.confirm_trip_fund_refund(
  uuid,uuid,numeric,text,uuid) from public;
grant execute on function public.confirm_trip_fund_refund(
  uuid,uuid,numeric,text,uuid) to authenticated;

-- Refunds are standalone ledger events; future fund corrections must not
-- remove them. There are no direct update/delete permissions on this table.
