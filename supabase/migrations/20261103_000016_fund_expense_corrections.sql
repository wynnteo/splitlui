-- Fund expense corrections. Apply after 20261103_000015.
-- Unlike trip_expenses, fund-paid purchases debit the pooled balance.
-- Edits/deletes restore/reapply that debit while holding a row lock.
alter table public.trip_fund_entries
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.trip_fund_corrections (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  fund_entry_id uuid not null,
  action text not null check (action in ('edit','delete')),
  before_snapshot jsonb not null,
  after_snapshot jsonb,
  changed_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists trip_fund_corrections_group_idx
  on public.trip_fund_corrections(group_id,created_at desc);
alter table public.trip_fund_corrections enable row level security;
revoke all on public.trip_fund_corrections from public,anon,authenticated;
grant select on public.trip_fund_corrections to authenticated;
drop policy if exists trip_fund_corrections_member_read on public.trip_fund_corrections;
create policy trip_fund_corrections_member_read
  on public.trip_fund_corrections for select to authenticated
  using (public.is_trip_member(group_id));

create or replace function public.correct_trip_fund_purchase(
  p_group uuid,p_entry uuid,p_expected_updated_at timestamptz,
  p_delete boolean,p_title text,p_amount numeric,p_currency text,
  p_rate_to_spending numeric,p_date date
) returns void language plpgsql security definer
set search_path = '' as $$
declare
  group_currency text;
  existing public.trip_fund_entries%rowtype;
  balance_now numeric;
  new_debit numeric(18,2);
  next_balance numeric(18,2);
  previous jsonb;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if p_delete is null then raise exception 'Action required'; end if;

  select spending_currency into group_currency
    from public.trip_groups where id=p_group for update;
  if not found then raise exception 'Group not found'; end if;
  select * into existing from public.trip_fund_entries
    where group_id=p_group and id=p_entry for update;
  if not found or existing.entry_type != 'expense' then
    raise exception 'Fund expense not found';
  end if;
  if existing.recorded_by != auth.uid() then
    raise exception 'Only the member who recorded this purchase can change it';
  end if;
  if existing.updated_at is distinct from p_expected_updated_at then
    raise exception 'Purchase was changed elsewhere. Refresh before editing';
  end if;

  if p_delete then
    new_debit := 0;
  else
    if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
      raise exception 'Invalid purchase description';
    end if;
    if p_amount is null or p_amount <= 0 or p_amount > 99999999999999.99
       or p_amount != round(p_amount,2) then
      raise exception 'Invalid purchase amount';
    end if;
    if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
      raise exception 'Invalid purchase currency';
    end if;
    if p_rate_to_spending is null or p_rate_to_spending <= 0
       or p_rate_to_spending > 99999999999999
       or p_rate_to_spending != round(p_rate_to_spending,8) then
      raise exception 'Invalid exchange rate';
    end if;
    if p_currency=group_currency and p_rate_to_spending != 1 then
      raise exception 'Same currency requires exchange rate 1';
    end if;
    if p_date is not null and
      (p_date < date '1990-01-01' or p_date > current_date + 1) then
      raise exception 'Invalid purchase date';
    end if;
    new_debit := round(p_amount*p_rate_to_spending,2);
    if new_debit <= 0 or new_debit > 99999999999999.99 then
      raise exception 'Converted purchase exceeds allowed range';
    end if;
  end if;

  select balance into balance_now from public.trip_fund_accounts
    where group_id=p_group for update;
  if not found then raise exception 'Fund account not found'; end if;
  next_balance := balance_now + existing.amount - new_debit;
  if next_balance < 0 or next_balance > 99999999999999.99 then
    raise exception 'Fund balance would become invalid or negative';
  end if;

  previous := to_jsonb(existing);
  update public.trip_fund_accounts set balance=next_balance,
    updated_at=clock_timestamp() where group_id=p_group;

  if p_delete then
    insert into public.trip_fund_corrections(
      group_id,fund_entry_id,action,before_snapshot,changed_by)
    values(p_group,p_entry,'delete',previous,auth.uid());
    delete from public.trip_fund_entries where group_id=p_group and id=p_entry;
  else
    update public.trip_fund_entries set
      description=btrim(p_title),amount=new_debit,
      original_amount=p_amount, original_currency=p_currency,
      rate_to_spending=p_rate_to_spending,receipt_date=p_date,
      updated_at=clock_timestamp()
    where group_id=p_group and id=p_entry;
    insert into public.trip_fund_corrections(
      group_id,fund_entry_id,action,before_snapshot,after_snapshot,changed_by)
    select p_group,p_entry,'edit',previous,to_jsonb(e),auth.uid()
      from public.trip_fund_entries e where e.id=p_entry;
  end if;
end; $$;
revoke all on function public.correct_trip_fund_purchase(
 uuid,uuid,timestamptz,boolean,text,numeric,text,numeric,date) from public;
grant execute on function public.correct_trip_fund_purchase(
 uuid,uuid,timestamptz,boolean,text,numeric,text,numeric,date)
 to authenticated;
