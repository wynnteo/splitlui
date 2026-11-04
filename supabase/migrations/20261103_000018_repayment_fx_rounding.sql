-- Phase 24: confirm actual repayment amounts without exchange-rate overpayment errors.
-- Run AFTER the existing repayment currency (000010) and reversal (000011)
-- migrations. Original paid_* fields always retain the ACTUAL currency/amount.
-- Ledger credit is capped at the debt still owed, rather than rejecting
-- cash received with FX rounding differences. Excess is NOT a new debt.
create or replace function public.record_trip_repayment_currency(
  p_group uuid,
  p_from uuid,
  p_to uuid,
  p_paid_amount numeric,
  p_currency text,
  p_rate_to_spending numeric,
  p_note text
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  spending text;
  converted numeric(18,2);
  ledger_credit numeric(18,2);
  debtor_net numeric;
  creditor_net numeric;
  receipt_id uuid;
begin
  if auth.uid() is null or auth.uid() != p_to then
    raise exception 'Only the recipient can confirm received money';
  end if;
  if p_from is null or p_to is null or p_from=p_to then
    raise exception 'Choose two different group members';
  end if;
  if p_paid_amount is null or p_paid_amount <= 0
    or p_paid_amount > 99999999999999.99
    or p_paid_amount != round(p_paid_amount,2) then
    raise exception 'Invalid received amount';
  end if;
  if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'Invalid payment currency';
  end if;
  if p_rate_to_spending is null or p_rate_to_spending <= 0
    or p_rate_to_spending > 99999999999999
    or p_rate_to_spending != round(p_rate_to_spending,8) then
    raise exception 'Invalid conversion rate';
  end if;
  if p_note is null or char_length(p_note)>120 then
    raise exception 'Invalid note';
  end if;

  -- Serialize receipts just like the existing core RPC.
  select spending_currency into spending from public.trip_groups
    where id=p_group for update;
  if spending is null or not public.is_trip_member(p_group) then
    raise exception 'Group not found or no access';
  end if;
  if not exists(select 1 from public.trip_members
       where group_id=p_group and user_id=p_from)
    or not exists(select 1 from public.trip_members
       where group_id=p_group and user_id=p_to) then
    raise exception 'Both parties must belong to this group';
  end if;
  if p_currency=spending and p_rate_to_spending!=1 then
    raise exception 'Same currency must have exchange rate 1';
  end if;
  converted := round(p_paid_amount*p_rate_to_spending,2);
  if converted <= 0 or converted > 99999999999999.99 then
    raise exception 'Invalid converted amount';
  end if;

  -- The ledger always uses the group spending currency. The actual
  -- payment itself is retained independently in paid_amount/currency.
  select
    (select coalesce(sum(amount_spending),0)
       from public.trip_expenses where group_id=p_group and paid_by=p_from)
    - (select coalesce(sum(share_spending),0)
       from public.trip_expense_shares where group_id=p_group and user_id=p_from)
    + (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and from_user_id=p_from and reversed_at is null)
    - (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and to_user_id=p_from and reversed_at is null)
  into debtor_net;

  select
    (select coalesce(sum(amount_spending),0)
       from public.trip_expenses where group_id=p_group and paid_by=p_to)
    - (select coalesce(sum(share_spending),0)
       from public.trip_expense_shares where group_id=p_group and user_id=p_to)
    + (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and from_user_id=p_to and reversed_at is null)
    - (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and to_user_id=p_to and reversed_at is null)
  into creditor_net;

  if debtor_net>=0 or creditor_net<=0 then
    raise exception 'No outstanding debt remains between these members';
  end if;
  ledger_credit := least(converted,-debtor_net,creditor_net);
  if ledger_credit<=0 then
    raise exception 'No positive debt remains to settle';
  end if;
  -- The existing RPC also locks this same group row (same transaction)
  -- and rechecks membership, outstanding balance and amount.
  receipt_id := public.record_trip_repayment(
    p_group,p_from,p_to,ledger_credit,p_note);
  update public.trip_repayments set
    paid_amount=p_paid_amount,
    paid_currency=p_currency,
    paid_rate_to_spending=p_rate_to_spending
  where id=receipt_id and group_id=p_group;
  return receipt_id;
end; $$;

revoke all on function public.record_trip_repayment_currency(
 uuid,uuid,uuid,numeric,text,numeric,text) from public;
grant execute on function public.record_trip_repayment_currency(
 uuid,uuid,uuid,numeric,text,numeric,text) to authenticated;

-- New clients can explicitly confirm an agreed full settlement without
-- forcing the agreed cash amount to match an FX-derived cent value.
create or replace function public.record_trip_repayment_agreed(
  p_group uuid,
  p_from uuid,
  p_to uuid,
  p_paid_amount numeric,
  p_currency text,
  p_rate_to_spending numeric,
  p_note text,
  p_settle_full boolean
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  spending text;
  converted numeric(18,2);
  ledger_credit numeric(18,2);
  debtor_net numeric;
  creditor_net numeric;
  receipt_id uuid;
begin
  if auth.uid() is null or auth.uid() != p_to then
    raise exception 'Only the recipient can confirm received money';
  end if;
  if p_from is null or p_to is null or p_from=p_to then
    raise exception 'Choose two different group members';
  end if;
  if p_paid_amount is null or p_paid_amount <= 0
    or p_paid_amount > 99999999999999.99
    or p_paid_amount != round(p_paid_amount,2) then
    raise exception 'Invalid received amount';
  end if;
  if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'Invalid payment currency';
  end if;
  if p_rate_to_spending is null or p_rate_to_spending <= 0
    or p_rate_to_spending > 99999999999999
    or p_rate_to_spending != round(p_rate_to_spending,8) then
    raise exception 'Invalid conversion rate';
  end if;
  if p_settle_full is null then
    raise exception 'Full or partial settlement selection required';
  end if;
  if p_note is null or char_length(p_note)>120 then
    raise exception 'Invalid note';
  end if;

  -- Serialize receipts just like the existing core RPC.
  select spending_currency into spending from public.trip_groups
    where id=p_group for update;
  if spending is null or not public.is_trip_member(p_group) then
    raise exception 'Group not found or no access';
  end if;
  if not exists(select 1 from public.trip_members
       where group_id=p_group and user_id=p_from)
    or not exists(select 1 from public.trip_members
       where group_id=p_group and user_id=p_to) then
    raise exception 'Both parties must belong to this group';
  end if;
  if p_currency=spending and p_rate_to_spending!=1 then
    raise exception 'Same currency must have exchange rate 1';
  end if;
  converted := round(p_paid_amount*p_rate_to_spending,2);
  if converted <= 0 or converted > 99999999999999.99 then
    raise exception 'Invalid converted amount';
  end if;

  -- The ledger always uses the group spending currency. The actual
  -- payment itself is retained independently in paid_amount/currency.
  select
    (select coalesce(sum(amount_spending),0)
       from public.trip_expenses where group_id=p_group and paid_by=p_from)
    - (select coalesce(sum(share_spending),0)
       from public.trip_expense_shares where group_id=p_group and user_id=p_from)
    + (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and from_user_id=p_from and reversed_at is null)
    - (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and to_user_id=p_from and reversed_at is null)
  into debtor_net;

  select
    (select coalesce(sum(amount_spending),0)
       from public.trip_expenses where group_id=p_group and paid_by=p_to)
    - (select coalesce(sum(share_spending),0)
       from public.trip_expense_shares where group_id=p_group and user_id=p_to)
    + (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and from_user_id=p_to and reversed_at is null)
    - (select coalesce(sum(amount_spending),0)
       from public.trip_repayments where group_id=p_group
         and to_user_id=p_to and reversed_at is null)
  into creditor_net;

  if debtor_net>=0 or creditor_net<=0 then
    raise exception 'No outstanding debt remains between these members';
  end if;
  -- A rounded agreed final transfer can clear the current suggested debt.
  -- A partial transfer only credits its converted actual value.
  ledger_credit := case when p_settle_full then
    least(-debtor_net,creditor_net)
    else least(converted,-debtor_net,creditor_net) end;
  if ledger_credit<=0 then
    raise exception 'No positive debt remains to settle';
  end if;
  -- The existing RPC also locks this same group row (same transaction)
  -- and rechecks membership, outstanding balance and amount.
  receipt_id := public.record_trip_repayment(
    p_group,p_from,p_to,ledger_credit,p_note);
  update public.trip_repayments set
    paid_amount=p_paid_amount,
    paid_currency=p_currency,
    paid_rate_to_spending=p_rate_to_spending
  where id=receipt_id and group_id=p_group;
  return receipt_id;
end; $$;

revoke all on function public.record_trip_repayment_agreed(
 uuid,uuid,uuid,numeric,text,numeric,text,boolean) from public;
grant execute on function public.record_trip_repayment_agreed(
 uuid,uuid,uuid,numeric,text,numeric,text,boolean) to authenticated;
