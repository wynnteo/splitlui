-- Phase 7: expenses may be paid in another currency than group spending.
-- Run AFTER Phase 3 expense migration. Existing records are preserved.
-- Convention: 1 expense-currency unit = p_rate_to_spending units of the
-- group's spending currency. The chosen rate is fixed per expense.

alter table public.trip_expenses
  add column if not exists currency text,
  add column if not exists rate_to_spending numeric(22,8),
  add column if not exists amount_spending numeric(18,2);

update public.trip_expenses e
set currency = coalesce(e.currency,g.spending_currency),
    rate_to_spending = coalesce(e.rate_to_spending,1),
    amount_spending = coalesce(e.amount_spending,e.amount)
from public.trip_groups g
where e.group_id=g.id
  and (e.currency is null or e.rate_to_spending is null or e.amount_spending is null);

alter table public.trip_expenses
  alter column currency set not null,
  alter column rate_to_spending set not null,
  alter column amount_spending set not null;
alter table public.trip_expenses
  add constraint trip_expenses_currency_code_check
  check (currency ~ '^[A-Z]{3}$'),
  add constraint trip_expenses_conversion_check
  check (rate_to_spending > 0 and amount_spending > 0);

alter table public.trip_expense_shares
  add column if not exists share_spending numeric(18,2);

update public.trip_expense_shares
set share_spending = share_amount
where share_spending is null;
alter table public.trip_expense_shares
  alter column share_spending set not null;
alter table public.trip_expense_shares
  add constraint trip_expense_shares_spending_nonnegative
  check (share_spending >= 0);

-- All mutations are atomic and validated server-side. Equal splits are
-- allocated independently in both currencies, so converted shares sum
-- exactly to the stored rounded converted expense total.
create or replace function public.add_trip_expense_v2(
  p_group uuid,
  p_title text,
  p_amount numeric,
  p_currency text,
  p_rate_to_spending numeric,
  p_paid_by uuid,
  p_split_between uuid[]
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  new_id uuid;
  group_spending text;
  converted numeric(18,2);
  participant_count integer;
  original_cents bigint;
  converted_cents bigint;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  select spending_currency into group_spending
    from public.trip_groups where id=p_group;
  if group_spending is null then raise exception 'Group not found'; end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Invalid expense title';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999999999.99
    or p_amount != round(p_amount,2) then
    raise exception 'Invalid amount; use up to two decimals';
  end if;
  if p_currency is null or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'Invalid expense currency';
  end if;
  if p_rate_to_spending is null or p_rate_to_spending <= 0
    or p_rate_to_spending > 99999999999999
    or p_rate_to_spending != round(p_rate_to_spending,8) then
    raise exception 'Invalid exchange rate; use up to eight decimals';
  end if;
  if p_currency = group_spending and p_rate_to_spending != 1 then
    raise exception 'Same currency must have rate 1';
  end if;
  converted := round(p_amount * p_rate_to_spending,2);
  if converted <= 0 or converted > 9999999999999999.99 then
    raise exception 'Converted amount out of range';
  end if;
  if not exists (
    select 1 from public.trip_members
    where group_id=p_group and user_id=p_paid_by
  ) then raise exception 'Payer must be a group member'; end if;

  participant_count := coalesce(array_length(p_split_between,1),0);
  if participant_count not between 1 and 50 then
    raise exception 'Select 1 to 50 participants';
  end if;
  if exists (
    select 1 from unnest(p_split_between) as s(user_id)
    where user_id is null or not exists (
      select 1 from public.trip_members m
      where m.group_id=p_group and m.user_id=s.user_id
    )
  ) then raise exception 'All participants must belong to group'; end if;
  if (select count(distinct user_id)
    from unnest(p_split_between) as s(user_id)) != participant_count then
    raise exception 'Duplicate participants';
  end if;

  original_cents := (p_amount * 100)::bigint;
  converted_cents := (converted * 100)::bigint;

  insert into public.trip_expenses (
    group_id,title,amount,currency,rate_to_spending,amount_spending,
    paid_by,created_by
  ) values (
    p_group,btrim(p_title),p_amount,p_currency,p_rate_to_spending,converted,
    p_paid_by,auth.uid()
  ) returning id into new_id;

  insert into public.trip_expense_shares (
    expense_id,group_id,user_id,share_amount,share_spending
  )
  select new_id,p_group,s.user_id,
    ((original_cents / participant_count) +
      case when s.idx <= (original_cents % participant_count)
        then 1 else 0 end)::numeric / 100,
    ((converted_cents / participant_count) +
      case when s.idx <= (converted_cents % participant_count)
        then 1 else 0 end)::numeric / 100
  from unnest(p_split_between) with ordinality as s(user_id,idx);

  return new_id;
end; $$;
revoke all on function public.add_trip_expense_v2(uuid,text,numeric,text,numeric,uuid,uuid[])
  from public;
grant execute on function public.add_trip_expense_v2(uuid,text,numeric,text,numeric,uuid,uuid[])
  to authenticated;

-- Preserve compatibility for older app versions. Their expenses still
-- use the group's spending currency with exchange rate 1.
create or replace function public.add_trip_expense(
  p_group uuid, p_title text, p_amount numeric,
  p_paid_by uuid, p_split_between uuid[]
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  spending text;
begin
  select spending_currency into spending
    from public.trip_groups where id=p_group;
  if spending is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  return public.add_trip_expense_v2(
    p_group,p_title,p_amount,spending,1,p_paid_by,p_split_between);
end; $$;
revoke all on function public.add_trip_expense(uuid,text,numeric,uuid,uuid[]) from public;
grant execute on function public.add_trip_expense(uuid,text,numeric,uuid,uuid[])
  to authenticated;
