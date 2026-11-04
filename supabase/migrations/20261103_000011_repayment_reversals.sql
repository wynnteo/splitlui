-- Phase 17 — Audited reversal of a mistaken repayment confirmation.
-- Run after Phase 16 repayment currency migration.
-- Only an original recipient can reverse their own confirmation.
-- The original receipt remains readable with reversal audit metadata.

alter table public.trip_repayments
  add column if not exists reversed_at timestamptz,
  add column if not exists reversed_bgit y uuid references auth.users(id),
  add column if not exists reversal_reason text;

create index if not exists trip_repayments_active_group_idx
  on public.trip_repayments (group_id, created_at desc)
  where reversed_at is null;

-- Existing server-side debt checks must disregard reversed receipts.
-- This preserves the recipient-only and serialized row-lock validation.
create or replace function public.record_trip_repayment(
  p_group uuid, p_from uuid, p_to uuid, p_amount numeric, p_note text
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  created_id uuid;
  debtor_net numeric;
  creditor_net numeric;
  existing_group uuid;
begin
  if auth.uid() is null or auth.uid() != p_to then
    raise exception 'Only the recipient can confirm money received';
  end if;
  if p_from is null or p_to is null or p_from = p_to then
    raise exception 'Choose two different group members';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 99999999999999.99
     or p_amount != round(p_amount,2) then
    raise exception 'Invalid repayment amount';
  end if;
  if p_note is null or char_length(p_note) > 120 then
    raise exception 'Invalid repayment note';
  end if;

  select id into existing_group from public.trip_groups
    where id=p_group for update;
  if existing_group is null or not public.is_trip_member(p_group) then
    raise exception 'Group not found or no access';
  end if;
  if not exists (
    select 1 from public.trip_members
    where group_id=p_group and user_id=p_from
  ) or not exists (
    select 1 from public.trip_members
    where group_id=p_group and user_id=p_to
  ) then raise exception 'Both parties must be current group members'; end if;

  -- Credit from expenses paid; debit from allocated shares.
  -- Prior received repayments reduce net credit; prior sent repayments
  -- reduce net debt. No Common Fund rows are included.
  select
    (select coalesce(sum(amount_spending),0)
      from public.trip_expenses
      where group_id=p_group and paid_by=p_from)
    - (select coalesce(sum(share_spending),0)
      from public.trip_expense_shares
      where group_id=p_group and user_id=p_from)
    + (select coalesce(sum(amount_spending),0)
      from public.trip_repayments
      where group_id=p_group and from_user_id=p_from
        and reversed_at is null)
    - (select coalesce(sum(amount_spending),0)
      from public.trip_repayments
      where group_id=p_group and to_user_id=p_from
        and reversed_at is null)
  into debtor_net;

  select
    (select coalesce(sum(amount_spending),0)
      from public.trip_expenses
      where group_id=p_group and paid_by=p_to)
    - (select coalesce(sum(share_spending),0)
      from public.trip_expense_shares
      where group_id=p_group and user_id=p_to)
    + (select coalesce(sum(amount_spending),0)
      from public.trip_repayments
      where group_id=p_group and from_user_id=p_to
        and reversed_at is null)
    - (select coalesce(sum(amount_spending),0)
      from public.trip_repayments
      where group_id=p_group and to_user_id=p_to
        and reversed_at is null)
  into creditor_net;

  if debtor_net >= 0 or creditor_net <= 0
     or p_amount > -debtor_net or p_amount > creditor_net then
    raise exception 'Repayment exceeds current outstanding debt';
  end if;

  insert into public.trip_repayments
    (group_id,from_user_id,to_user_id,amount_spending,note,recorded_by)
  values (p_group,p_from,p_to,p_amount,btrim(p_note),auth.uid())
  returning id into created_id;

  return created_id;
end; $$;


-- Mark a receipt reversed; do not delete or directly alter ledger amounts.
create or replace function public.reverse_trip_repayment(
  p_group uuid, p_receipt uuid, p_reason text
)
returns void language plpgsql security definer
set search_path = '' as $$
declare
  existing_group uuid;
  recipient uuid;
  reversal_time timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Sign in required';
  end if;
  if p_reason is null or char_length(btrim(p_reason)) not between 3 and 120 then
    raise exception 'Please provide a reason (3–120 characters)';
  end if;

  -- Serialize with receipt insertion and other reversals of the same group.
  select id into existing_group from public.trip_groups
    where id=p_group for update;
  if existing_group is null or not public.is_trip_member(p_group) then
    raise exception 'Group not found or no access';
  end if;
  select to_user_id, reversed_at into recipient,reversal_time
    from public.trip_repayments
    where group_id=p_group and id=p_receipt for update;

  if recipient is null then
    raise exception 'Repayment not found';
  end if;
  if recipient != auth.uid() then
    raise exception 'Only the payment recipient can reverse this confirmation';
  end if;
  if reversal_time is not null then
    raise exception 'Repayment already reversed';
  end if;

  update public.trip_repayments
    set reversed_at=now(), reversed_by=auth.uid(),
        reversal_reason=btrim(p_reason)
    where group_id=p_group and id=p_receipt and reversed_at is null;
end; $$;

revoke all on function public.reverse_trip_repayment(uuid,uuid,text) from public;
grant execute on function public.reverse_trip_repayment(uuid,uuid,text)
  to authenticated;
