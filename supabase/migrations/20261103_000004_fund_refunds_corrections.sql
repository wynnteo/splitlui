-- SplitLui Phase 5: auditable fund refunds and one-time reversals.
-- Run AFTER 20261103_000003_trip_common_fund.sql.
-- Existing transactions and balances remain untouched.

alter table public.trip_fund_entries
  add column if not exists reverses_entry_id uuid
    references public.trip_fund_entries(id);

alter table public.trip_fund_entries
  drop constraint if exists trip_fund_entries_entry_type_check;
alter table public.trip_fund_entries
  drop constraint if exists trip_fund_entries_check;

alter table public.trip_fund_entries
  add constraint trip_fund_entries_type_v2_check
    check (entry_type in ('contribution','expense','refund','reversal'));
alter table public.trip_fund_entries
  add constraint trip_fund_entries_shape_v2_check
    check (
      (entry_type in ('contribution','refund')
        and member_id is not null and reverses_entry_id is null)
      or
      (entry_type = 'expense'
        and member_id is null and reverses_entry_id is null)
      or
      (entry_type = 'reversal'
        and member_id is null and reverses_entry_id is not null)
    );
create unique index if not exists trip_fund_one_reversal_per_entry_idx
  on public.trip_fund_entries(reverses_entry_id)
  where reverses_entry_id is not null;

-- Only the organiser records cash actually handed back to a member.
-- This does not automatically determine fair refund allocations.
create or replace function public.refund_trip_fund_member(
  p_group uuid, p_member uuid, p_amount numeric, p_description text
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  available numeric(18,2);
  new_id uuid;
begin
  if auth.uid() is null or not exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = auth.uid() and role = 'owner'
  ) then raise exception 'Only the group organiser can record refunds'; end if;

  if p_member is null or not exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = p_member
  ) then raise exception 'Refund recipient must be a group member'; end if;

  if p_amount is null or p_amount <= 0 or
     p_amount > 9999999999999999.99 or p_amount != round(p_amount,2) then
    raise exception 'Invalid refund amount'; end if;

  if p_description is null or
     char_length(btrim(p_description)) not between 1 and 120 then
    raise exception 'Refund note required'; end if;

  select balance into available
  from public.trip_fund_accounts
  where group_id = p_group for update;
  if available is null or available < p_amount then
    raise exception 'Insufficient common fund balance for refund'; end if;

  update public.trip_fund_accounts
    set balance = balance - p_amount, updated_at = now()
    where group_id = p_group;

  insert into public.trip_fund_entries
    (group_id,entry_type,amount,member_id,description,recorded_by)
  values
    (p_group,'refund',p_amount,p_member,btrim(p_description),auth.uid())
  returning id into new_id;
  return new_id;
end; $$;
revoke all on function public.refund_trip_fund_member(uuid,uuid,numeric,text)
  from public;
grant execute on function public.refund_trip_fund_member(uuid,uuid,numeric,text)
  to authenticated;

-- A reversal is an immutable compensating entry, NEVER an edit/delete.
-- Only original contribution/expense/refund entries can be reversed.
-- Row locking + unique reversal reference prevents double reversals.
create or replace function public.reverse_trip_fund_entry(
  p_group uuid, p_entry uuid, p_reason text
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  original public.trip_fund_entries%rowtype;
  available numeric(18,2);
  delta numeric(18,2);
  new_id uuid;
begin
  if auth.uid() is null or not exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = auth.uid() and role = 'owner'
  ) then raise exception 'Only the group organiser can reverse entries'; end if;

  if p_reason is null or char_length(btrim(p_reason)) not between 1 and 120 then
    raise exception 'A correction reason is required'; end if;

  -- Serialize all fund edits on the same group's balance row.
  select balance into available from public.trip_fund_accounts
    where group_id = p_group for update;
  if available is null then raise exception 'Fund not found'; end if;

  select * into original from public.trip_fund_entries
    where group_id = p_group and id = p_entry;
  if not found then raise exception 'Entry not found in this group'; end if;
  if original.entry_type = 'reversal' then
    raise exception 'A reversal cannot be reversed'; end if;
  if exists (
    select 1 from public.trip_fund_entries
      where group_id = p_group and reverses_entry_id = p_entry
  ) then raise exception 'This entry was already reversed'; end if;

  delta := case when original.entry_type = 'contribution'
    then -original.amount else original.amount end;

  if available + delta < 0 then
    raise exception 'Insufficient balance to reverse that contribution';
  end if;

  update public.trip_fund_accounts
    set balance = balance + delta, updated_at = now()
    where group_id = p_group;

  insert into public.trip_fund_entries (
    group_id,entry_type,amount,member_id,
    description,recorded_by,reverses_entry_id
  ) values (
    p_group,'reversal',original.amount,null,
    btrim(p_reason),auth.uid(),p_entry
  ) returning id into new_id;

  return new_id;
end; $$;
revoke all on function public.reverse_trip_fund_entry(uuid,uuid,text)
  from public;
grant execute on function public.reverse_trip_fund_entry(uuid,uuid,text)
  to authenticated;

-- Revoke legacy defaults again; all table mutations remain RPC-only.
revoke all on public.trip_fund_entries, public.trip_fund_accounts
  from anon, authenticated;
grant select on public.trip_fund_entries, public.trip_fund_accounts
  to authenticated;
