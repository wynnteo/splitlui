-- SplitLui Phase 3: shared member-paid expenses (v1).
-- Run AFTER 20261103_000001_trip_groups.sql.
-- Money is in the group's spending currency; settlement conversion is later.
-- This phase does not handle common-fund payments.

create table if not exists public.trip_expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  amount numeric(18,2) not null check (amount > 0),
  paid_by uuid not null references auth.users(id),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  unique (id, group_id)
);
create index if not exists trip_expenses_group_created_idx
  on public.trip_expenses(group_id, created_at desc);

create table if not exists public.trip_expense_shares (
  expense_id uuid not null,
  group_id uuid not null,
  user_id uuid not null references auth.users(id),
  share_amount numeric(18,2) not null check (share_amount >= 0),
  primary key (expense_id, user_id),
  foreign key (expense_id, group_id) references public.trip_expenses(id, group_id)
    on delete cascade
);
create index if not exists trip_expense_shares_group_idx
  on public.trip_expense_shares(group_id);

alter table public.trip_expenses enable row level security;
alter table public.trip_expense_shares enable row level security;

revoke all on public.trip_expenses, public.trip_expense_shares from anon;
revoke all on public.trip_expenses, public.trip_expense_shares from authenticated;
grant select on public.trip_expenses, public.trip_expense_shares to authenticated;

drop policy if exists trip_expenses_member_read on public.trip_expenses;
create policy trip_expenses_member_read on public.trip_expenses
  for select to authenticated using (public.is_trip_member(group_id));

drop policy if exists trip_expense_shares_member_read on public.trip_expense_shares;
create policy trip_expense_shares_member_read on public.trip_expense_shares
  for select to authenticated using (public.is_trip_member(group_id));

-- An atomic RPC validates payer, selected participants and exact cent allocation.
-- Explicitly forbid duplicates or non-members. Only equal splits for now.
create or replace function public.add_trip_expense(
  p_group uuid,
  p_title text,
  p_amount numeric,
  p_paid_by uuid,
  p_split_between uuid[]
)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  new_id uuid;
  participant_count integer;
  amount_cents bigint;
  base_cents bigint;
  remainder_cents bigint;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Invalid expense title';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999999999.99
     or p_amount != round(p_amount, 2) then
    raise exception 'Invalid amount; use at most 2 decimal places';
  end if;
  if not exists (
    select 1 from public.trip_members
    where group_id=p_group and user_id=p_paid_by
  ) then
    raise exception 'Payer must be a group member';
  end if;
  participant_count := coalesce(array_length(p_split_between,1),0);
  if participant_count < 1 or participant_count > 50 then
    raise exception 'Select 1 to 50 participants';
  end if;
  if exists (
    select 1 from unnest(p_split_between) as s(user_id)
    where user_id is null or not exists (
      select 1 from public.trip_members m
      where m.group_id=p_group and m.user_id=s.user_id
    )
  ) then
    raise exception 'All participants must belong to the group';
  end if;
  if (select count(distinct user_id) from unnest(p_split_between) as s(user_id))
       != participant_count then
    raise exception 'Duplicate participants';
  end if;

  amount_cents := (p_amount * 100)::bigint;
  base_cents := amount_cents / participant_count;
  remainder_cents := amount_cents % participant_count;

  insert into public.trip_expenses(group_id,title,amount,paid_by,created_by)
  values (p_group,btrim(p_title),p_amount,p_paid_by,auth.uid())
  returning id into new_id;

  insert into public.trip_expense_shares(expense_id,group_id,user_id,share_amount)
  select new_id,p_group,s.user_id,
    (base_cents + case when s.idx <= remainder_cents then 1 else 0 end)::numeric / 100
  from unnest(p_split_between) with ordinality as s(user_id,idx);

  return new_id;
end; $$;
revoke all on function public.add_trip_expense(uuid,text,numeric,uuid,uuid[]) from public;
grant execute on function public.add_trip_expense(uuid,text,numeric,uuid,uuid[]) to authenticated;
