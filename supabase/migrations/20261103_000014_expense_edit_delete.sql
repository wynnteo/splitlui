-- Phase 20: receipt transaction dates and safe member expense editing.
-- Requires: 000006 expense currencies and 000011 repayment reversals.
-- Only expense creators may edit/delete. No edit/delete after any active
-- confirmed repayment in the group: the existing settlement ledger cannot
-- yet safely reassign already recorded debt.
alter table public.trip_expenses
  add column if not exists receipt_date date,
  add column if not exists updated_at timestamptz not null default now();
alter table public.trip_fund_entries
  add column if not exists receipt_date date;

-- Date metadata cannot change financial balances and is attached to the
-- expense by its original recorder only.
create or replace function public.set_trip_receipt_date(
  p_group uuid, p_expense uuid, p_fund_entry uuid, p_date date
) returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if (p_expense is null) = (p_fund_entry is null) then
    raise exception 'Expected one receipt target';
  end if;
  if p_date is not null and
     (p_date < date '1990-01-01' or p_date > current_date + 1) then
    raise exception 'Invalid receipt date';
  end if;
  if p_expense is not null then
    update public.trip_expenses set receipt_date=p_date
      where group_id=p_group and id=p_expense and created_by=auth.uid();
  else
    update public.trip_fund_entries set receipt_date=p_date
      where group_id=p_group and id=p_fund_entry and recorded_by=auth.uid()
        and entry_type='expense';
  end if;
  if not found then raise exception 'Expense not found or no permission'; end if;
end; $$;
revoke all on function public.set_trip_receipt_date(uuid,uuid,uuid,date) from public;
grant execute on function public.set_trip_receipt_date(uuid,uuid,uuid,date) to authenticated;

create or replace function public.edit_trip_expense(
  p_group uuid, p_expense uuid, p_expected_updated_at timestamptz,
  p_title text, p_amount numeric, p_currency text,
  p_rate_to_spending numeric, p_paid_by uuid,
  p_split_between uuid[], p_date date
) returns void language plpgsql security definer
set search_path = '' as $$
declare
  current_expense record;
  locked_group uuid;
  group_spending text;
  converted numeric(18,2);
  participant_count integer;
  original_cents bigint;
  converted_cents bigint;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  select id,spending_currency into locked_group,group_spending
    from public.trip_groups where id=p_group for update;
  if locked_group is null then raise exception 'Group not found'; end if;
  select * into current_expense from public.trip_expenses
    where id=p_expense and group_id=p_group for update;
  if not found then raise exception 'Expense not found'; end if;
  if current_expense.created_by != auth.uid() then
    raise exception 'Only the expense creator can edit';
  end if;
  if current_expense.updated_at is distinct from p_expected_updated_at then
    raise exception 'Expense changed on another device; refresh before editing';
  end if;
  if exists (select 1 from public.trip_repayments
     where group_id=p_group and reversed_at is null) then
    raise exception 'Expense edits are blocked after confirmed repayments';
  end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Invalid expense title';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999999999.99
     or p_amount != round(p_amount,2) then
    raise exception 'Invalid expense amount';
  end if;
  if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'Invalid currency';
  end if;
  if p_rate_to_spending is null or p_rate_to_spending <= 0
     or p_rate_to_spending > 99999999999999
     or p_rate_to_spending != round(p_rate_to_spending,8) then
    raise exception 'Invalid exchange rate';
  end if;
  if p_currency=group_spending and p_rate_to_spending != 1 then
    raise exception 'Same currency must have exchange rate 1';
  end if;
  if not exists (select 1 from public.trip_members
    where group_id=p_group and user_id=p_paid_by) then
    raise exception 'Payer must belong to the group';
  end if;
  participant_count:=coalesce(array_length(p_split_between,1),0);
  if participant_count not between 1 and 50 then
    raise exception 'Select 1 to 50 participants';
  end if;
  if exists(select 1 from unnest(p_split_between) as s(user_id)
    where user_id is null or not exists(select 1 from public.trip_members m
      where m.group_id=p_group and m.user_id=s.user_id))
    or (select count(distinct user_id)
      from unnest(p_split_between) as s(user_id)) != participant_count then
    raise exception 'Invalid or repeated participants';
  end if;
  if p_date is not null and
     (p_date < date '1990-01-01' or p_date > current_date + 1) then
    raise exception 'Invalid receipt date';
  end if;

  converted:=round(p_amount * p_rate_to_spending,2);
  if converted <= 0 or converted > 9999999999999999.99 then
    raise exception 'Invalid converted amount';
  end if;
  original_cents:=(p_amount*100)::bigint;
  converted_cents:=(converted*100)::bigint;

  update public.trip_expenses set
    title=btrim(p_title),amount=p_amount,currency=p_currency,
    rate_to_spending=p_rate_to_spending,amount_spending=converted,
    paid_by=p_paid_by,receipt_date=p_date,updated_at=clock_timestamp()
    where id=p_expense and group_id=p_group;

  delete from public.trip_expense_shares where expense_id=p_expense;
  insert into public.trip_expense_shares
    (expense_id,group_id,user_id,share_amount,share_spending)
  select p_expense,p_group,s.user_id,
    ((original_cents/participant_count) +
      case when s.idx <= (original_cents%participant_count) then 1 else 0 end)::numeric / 100,
    ((converted_cents/participant_count) +
      case when s.idx <= (converted_cents%participant_count) then 1 else 0 end)::numeric / 100
  from unnest(p_split_between) with ordinality as s(user_id,idx);
end; $$;
revoke all on function public.edit_trip_expense(
 uuid,uuid,timestamptz,text,numeric,text,numeric,uuid,uuid[],date) from public;
grant execute on function public.edit_trip_expense(
 uuid,uuid,timestamptz,text,numeric,text,numeric,uuid,uuid[],date) to authenticated;

create or replace function public.delete_trip_expense(
  p_group uuid,p_expense uuid,p_expected_updated_at timestamptz
) returns void language plpgsql security definer
set search_path = '' as $$
declare
  locked_group uuid;
  row_record record;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  select id into locked_group from public.trip_groups
    where id=p_group for update;
  if locked_group is null then raise exception 'Group not found'; end if;
  select created_by,updated_at into row_record from public.trip_expenses
    where group_id=p_group and id=p_expense for update;
  if not found then raise exception 'Expense not found'; end if;
  if row_record.created_by != auth.uid() then
    raise exception 'Only the expense creator can delete';
  end if;
  if row_record.updated_at is distinct from p_expected_updated_at then
    raise exception 'Expense changed; refresh before deleting';
  end if;
  if exists(select 1 from public.trip_repayments
    where group_id=p_group and reversed_at is null) then
    raise exception 'Expense deletion blocked after confirmed repayments';
  end if;
  delete from public.trip_expenses where group_id=p_group and id=p_expense;
  -- Linked receipt metadata and operation rows cascade. Unlinked Storage
  -- objects must be cleaned separately by the uploader.
end; $$;
revoke all on function public.delete_trip_expense(uuid,uuid,timestamptz)
  from public;
grant execute on function public.delete_trip_expense(uuid,uuid,timestamptz)
  to authenticated;
