-- Phase 16: record the actual currency received (SGD, MYR, etc.)
-- while maintaining the canonical repayment ledger in group spending currency.
-- Run after 20261103_000007_trip_repayments.sql.

alter table public.trip_repayments
  add column if not exists paid_amount numeric(18,2),
  add column if not exists paid_currency text,
  add column if not exists paid_rate_to_spending numeric(22,8);

-- Existing receipts were entered in the spending currency.
update public.trip_repayments r
set paid_amount = coalesce(r.paid_amount, r.amount_spending),
    paid_currency = coalesce(r.paid_currency, g.spending_currency),
    paid_rate_to_spending = coalesce(r.paid_rate_to_spending, 1)
from public.trip_groups g
where g.id = r.group_id
  and (r.paid_amount is null or r.paid_currency is null
       or r.paid_rate_to_spending is null);

alter table public.trip_repayments
  alter column paid_amount set not null,
  alter column paid_currency set not null,
  alter column paid_rate_to_spending set not null;

-- The canonical amount_spending remains the amount reduced from personal
-- balances; paid_* is the amount/currency the recipient actually received.
create or replace function public.record_trip_repayment_currency(
  p_group uuid,
  p_from uuid,
  p_to uuid,
  p_paid_amount numeric,
  p_currency text,
  p_rate_to_spending numeric,
  p_note text
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  spending text;
  converted numeric;
  receipt_id uuid;
begin
  if auth.uid() is null or auth.uid() != p_to then
    raise exception 'Only the recipient can confirm received money';
  end if;
  if p_paid_amount is null or p_paid_amount <= 0
     or p_paid_amount > 99999999999999.99
     or p_paid_amount != round(p_paid_amount,2) then
    raise exception 'Invalid payment amount';
  end if;
  if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'Invalid payment currency';
  end if;
  if p_rate_to_spending is null or p_rate_to_spending <= 0
     or p_rate_to_spending > 99999999999999
     or p_rate_to_spending != round(p_rate_to_spending,8) then
    raise exception 'Invalid conversion rate';
  end if;

  select spending_currency into spending
  from public.trip_groups where id = p_group;
  if spending is null or not public.is_trip_member(p_group) then
    raise exception 'Group not found or no access';
  end if;
  if p_currency = spending and p_rate_to_spending != 1 then
    raise exception 'Payment in spending currency must use rate 1';
  end if;

  converted := round(p_paid_amount * p_rate_to_spending,2);
  if converted <= 0 or converted > 99999999999999.99 then
    raise exception 'Converted amount out of range';
  end if;

  -- The original function locks the group and validates current net
  -- outstanding debt and recipient identity under concurrency. Reuse it
  -- instead of bypassing safeguards or duplicating accounting.
  receipt_id := public.record_trip_repayment(
    p_group, p_from, p_to, converted, p_note);

  update public.trip_repayments
  set paid_amount = p_paid_amount,
      paid_currency = p_currency,
      paid_rate_to_spending = p_rate_to_spending
  where id = receipt_id and group_id = p_group;

  return receipt_id;
end; $$;

revoke all on function public.record_trip_repayment_currency(
  uuid,uuid,uuid,numeric,text,numeric,text) from public;
grant execute on function public.record_trip_repayment_currency(
  uuid,uuid,uuid,numeric,text,numeric,text) to authenticated;

-- Older versions may call record_trip_repayment, which inserted only the
-- canonical amount. Backfill those records on write as well.
create or replace function public.set_trip_repayment_legacy_currency()
returns trigger language plpgsql security definer
set search_path = '' as $$
begin
  if new.paid_amount is null then
    new.paid_amount := new.amount_spending;
    select g.spending_currency into new.paid_currency
    from public.trip_groups g where g.id = new.group_id;
    new.paid_rate_to_spending := 1;
  end if;
  return new;
end; $$;

drop trigger if exists trip_repayments_legacy_currency on public.trip_repayments;
create trigger trip_repayments_legacy_currency
before insert on public.trip_repayments
for each row execute function public.set_trip_repayment_legacy_currency();
