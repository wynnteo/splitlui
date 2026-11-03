-- Phase 19: retry-safe offline outbox for member-paid shared expenses.
-- Apply after Phase 20 expense edit/delete (000014). Do not use for fund spending.
-- A client-generated UUID identifies one immutable expense request.
-- Keep operation tombstones even after deleting an expense so retries cannot
-- recreate a transaction that was deliberately removed.
create table if not exists public.trip_expense_operations (
  operation_id uuid primary key,
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  request_payload jsonb not null,
  expense_id uuid unique references public.trip_expenses(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists trip_expense_operations_group_idx
  on public.trip_expense_operations(group_id,created_at desc);
alter table public.trip_expense_operations enable row level security;
revoke all on public.trip_expense_operations from public,anon,authenticated;
grant select on public.trip_expense_operations to authenticated;
drop policy if exists trip_expense_operations_author_read on public.trip_expense_operations;
create policy trip_expense_operations_author_read
  on public.trip_expense_operations for select to authenticated
  using (created_by=auth.uid() and public.is_trip_member(group_id));

create or replace function public.add_trip_expense_offline(
  p_operation uuid,
  p_group uuid,
  p_title text,
  p_amount numeric,
  p_currency text,
  p_rate_to_spending numeric,
  p_paid_by uuid,
  p_split_between uuid[],
  p_date date
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  existing record;
  request_body jsonb;
  created uuid;
  locked_group uuid;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if p_operation is null then raise exception 'Operation ID required'; end if;
  if p_date is not null and
     (p_date < date '1990-01-01' or p_date > current_date + 1) then
    raise exception 'Invalid receipt date';
  end if;
  request_body := jsonb_build_object(
    'group_id',p_group, 'title',btrim(p_title),
    'amount',p_amount,'currency',p_currency,
    'rate_to_spending',p_rate_to_spending,'paid_by',p_paid_by,
    'split_between',to_jsonb(p_split_between),'receipt_date',p_date);

  -- Serialize new and retried requests for the same group. The ledger RPC
  -- itself validates participants and money. No second insert on retry.
  select id into locked_group from public.trip_groups
    where id=p_group for update;
  if locked_group is null then raise exception 'Group not found'; end if;

  select * into existing from public.trip_expense_operations
    where operation_id=p_operation;
  if found then
    if existing.group_id != p_group or existing.created_by != auth.uid()
        or existing.request_payload != request_body then
      raise exception 'Operation ID reused with different data or user';
    end if;
    if existing.expense_id is null then
      raise exception 'This offline expense was already deleted';
    end if;
    return existing.expense_id;
  end if;

  created := public.add_trip_expense_v2(
    p_group,p_title,p_amount,p_currency,p_rate_to_spending,
    p_paid_by,p_split_between);
  update public.trip_expenses set receipt_date=p_date where id=created;
  insert into public.trip_expense_operations(
    operation_id,group_id,created_by,request_payload,expense_id)
  values(p_operation,p_group,auth.uid(),request_body,created);
  return created;
end; $$;
revoke all on function public.add_trip_expense_offline(
 uuid,uuid,text,numeric,text,numeric,uuid,uuid[],date) from public;
grant execute on function public.add_trip_expense_offline(
 uuid,uuid,text,numeric,text,numeric,uuid,uuid[],date) to authenticated;
