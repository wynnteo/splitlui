-- Phase 9: confirmed manual repayments. Run after Phase 7 expense currencies.
-- Repayments are recorded in the group's SPENDING currency, never
-- automatically transferred via PayNow/bank services.

create table if not exists public.trip_repayments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  from_user_id uuid not null references auth.users(id),
  to_user_id uuid not null references auth.users(id),
  amount_spending numeric(18,2) not null check (amount_spending > 0),
  note text not null default '' check (char_length(note) <= 120),
  recorded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  check (from_user_id != to_user_id)
);
create index if not exists trip_repayments_group_created_idx
  on public.trip_repayments(group_id,created_at desc,id desc);

alter table public.trip_repayments enable row level security;
revoke all on public.trip_repayments from anon, authenticated;
grant select on public.trip_repayments to authenticated;
drop policy if exists trip_repayments_member_read on public.trip_repayments;
create policy trip_repayments_member_read on public.trip_repayments
  for select to authenticated using (public.is_trip_member(group_id));

-- Only the recipient can attest to RECEIVING a repayment.
-- Prevents another member from unilaterally marking someone else's debt paid.
-- Serializes concurrent receipts by locking the parent group row.
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
      where group_id=p_group and from_user_id=p_from)
    - (select coalesce(sum(amount_spending),0)
      from public.trip_repayments
      where group_id=p_group and to_user_id=p_from)
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
      where group_id=p_group and from_user_id=p_to)
    - (select coalesce(sum(amount_spending),0)
      from public.trip_repayments
      where group_id=p_group and to_user_id=p_to)
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

revoke all on function public.record_trip_repayment(uuid,uuid,uuid,numeric,text)
  from public;
grant execute on function public.record_trip_repayment(uuid,uuid,uuid,numeric,text)
  to authenticated;

-- No direct client writes. Corrections and disputes require a future
-- audited reversal flow; don't represent unverified transfers as settled.
