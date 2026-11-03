-- Phase 12: record foreign-currency purchases paid by the common fund.
-- One fund ledger expense is inserted. No trip_expenses row/share is created;
-- this avoids charging members again in the settlement calculator.
-- Run after trip_common_fund and expense_currencies migrations.

alter table public.trip_fund_entries
  add column if not exists original_amount numeric(18,2),
  add column if not exists original_currency text,
  add column if not exists rate_to_spending numeric(22,8);
  
create or replace function public.record_trip_fund_purchase(
  p_group uuid,
  p_title text,
  p_amount numeric,
  p_currency text,
  p_rate_to_spending numeric
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  group_currency text;
  converted numeric;
  balance_now numeric;
  new_id uuid;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;

  select spending_currency into group_currency
    from public.trip_groups where id = p_group;
  if group_currency is null then raise exception 'Group not found'; end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Enter a valid expense title';
  end if;
  if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'Invalid currency';
  end if;
  if p_amount is null or p_amount <= 0
    or p_amount > 99999999999999.99 or p_amount != round(p_amount, 2) then
    raise exception 'Invalid amount';
  end if;
  if p_rate_to_spending is null or p_rate_to_spending <= 0
    or p_rate_to_spending > 99999999999999
    or p_rate_to_spending != round(p_rate_to_spending, 8) then
    raise exception 'Invalid exchange rate';
  end if;
  if p_currency = group_currency and p_rate_to_spending != 1 then
    raise exception 'Same currency requires exchange rate 1';
  end if;

  converted := round(p_amount * p_rate_to_spending, 2);
  if converted <= 0 or converted > 99999999999999.99 then
    raise exception 'Converted purchase amount is out of range';
  end if;

  insert into public.trip_fund_accounts(group_id)
    values (p_group) on conflict (group_id) do nothing;
  select balance into balance_now from public.trip_fund_accounts
    where group_id = p_group for update;
  if balance_now < converted then
    raise exception 'Insufficient common fund balance';
  end if;

  update public.trip_fund_accounts
    set balance = balance - converted, updated_at = now()
    where group_id = p_group;

  insert into public.trip_fund_entries(
    group_id, entry_type, amount, member_id,
    description, recorded_by, original_amount, original_currency,
    rate_to_spending
  ) values (
    p_group, 'expense', converted, null,
    btrim(p_title), auth.uid(), p_amount, p_currency,
    p_rate_to_spending
  ) returning id into new_id;

  return new_id;
end; $$;

revoke all on function public.record_trip_fund_purchase(uuid,text,numeric,text,numeric)
  from public;
grant execute on function public.record_trip_fund_purchase(uuid,text,numeric,text,numeric)
  to authenticated;
