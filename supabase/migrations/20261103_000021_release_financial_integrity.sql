-- Financial integrity patch: apply after 20261103_000020.
-- Existing transactions are untouched. Old RPC signature remains compatible.
-- New security checks live in Postgres; hiding UI buttons is not security.
-- Group owners verify money received; ordinary members can still use pooled
-- money for expenses as before.
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
  -- Lock the trip first to serialize membership removal and fund writes.
  perform 1 from public.trip_groups where id=p_group for update;
  if not found then raise exception 'Group not found'; end if;
  -- Contributions represent cash actually received, not a member's claim.
  -- The organiser is the only person allowed to confirm pooled receipts.
  if p_type='contribution' and not exists (
    select 1 from public.trip_members
    where group_id=p_group and user_id=auth.uid() and role='owner'
  ) then
    raise exception 'Only the group owner can confirm received fund contributions';
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

revoke all on function public.record_trip_fund_entry(
 uuid,text,numeric,uuid,text) from public;
grant execute on function public.record_trip_fund_entry(
 uuid,text,numeric,uuid,text) to authenticated;

-- Full-settlement rounding tolerance: <= 2% or 1 spending unit.
-- Partial payments use actual received FX-converted amount.
create or replace function public.record_trip_repayment_agreed(
  p_group uuid,
  p_from uuid,
  p_to uuid,
  p_paid_amount numeric,
  p_currency text,
  p_rate_to_spending numeric,
  p_note text,
  p_settle_full boolean,
  p_suggested_spending numeric
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
  if p_suggested_spending is null or p_suggested_spending <= 0
    or p_suggested_spending > 99999999999999.99
    or p_suggested_spending != round(p_suggested_spending,2) then
    raise exception 'Invalid suggested settlement';
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
  -- Allow a rounded final transfer (e.g., SGD 135 instead of SGD 135.23),
  -- but do not allow a small confirmed cash payment to silently wipe out
  -- much more debt. Full settlement may waive at most 2% (or one unit of
  -- group spending currency for tiny balances) of the selected suggestion.
  -- Larger negotiated discounts require an explicit future adjustment flow.
  if p_settle_full and converted < p_suggested_spending
    and p_suggested_spending - converted >
      greatest(1.00::numeric, p_suggested_spending * 0.02) then
    raise exception 'Received amount is too far below the selected debt for full settlement; choose partial payment';
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
    least(p_suggested_spending,-debtor_net,creditor_net)
    else least(converted,p_suggested_spending,-debtor_net,creditor_net) end;
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
 uuid,uuid,uuid,numeric,text,numeric,text,boolean,numeric) from public;
grant execute on function public.record_trip_repayment_agreed(
 uuid,uuid,uuid,numeric,text,numeric,text,boolean,numeric) to authenticated;
