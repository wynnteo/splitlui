-- Flexible original-currency splits for member-paid expenses.
-- Requires expense edit/delete 000014 and offline operations 000015.
-- Fund purchases and repayment accounting are intentionally unchanged.

-- Internal allocator. Only RPCs defined below can invoke it: no grant to app.
-- The original share amounts must sum exactly to the saved expense amount.
-- Converted-currency cents are distributed by largest remainder proportional
-- to original shares; rounding is stable by participant order.
create or replace function public._apply_trip_custom_shares(
  p_group uuid,p_expense uuid,p_members uuid[],p_amounts numeric[]
) returns void language plpgsql security definer
set search_path = '' as $$
declare
  e public.trip_expenses%rowtype;
  n integer;
begin
  select * into e from public.trip_expenses
    where group_id=p_group and id=p_expense for update;
  if not found then raise exception 'Expense not found'; end if;
  n:=coalesce(array_length(p_members,1),0);
  if n<1 or n>50 or n!=coalesce(array_length(p_amounts,1),0) then
    raise exception 'Invalid participant/allocation count';
  end if;
  if (select count(distinct u) from unnest(p_members) u)!=n
    or exists(select 1 from unnest(p_members) u
      where u is null or not exists(
        select 1 from public.trip_members
        where group_id=p_group and user_id=u)) then
    raise exception 'Invalid or duplicate participant';
  end if;
  if exists(select 1 from unnest(p_amounts) amt
      where amt is null or amt < 0 or amt != round(amt,2)) then
    raise exception 'Share amounts must be positive cents or zero';
  end if;
  if (select coalesce(sum(amt),0) from unnest(p_amounts) amt)!=e.amount then
    raise exception 'Shares must sum exactly to the expense total';
  end if;

  delete from public.trip_expense_shares
    where group_id=p_group and expense_id=p_expense;

  with positions as (
    select p_members[i] as member_id,
      p_amounts[i] as original_amount,
      i as position,
      (e.amount_spending*100)::bigint as converted_cents,
      e.amount as original_total
    from generate_series(1,n) as i
  ), quota as (
    select *,
      (converted_cents::numeric * original_amount / original_total)
        as raw_cents
    from positions
  ), allocated as (
    select *,
      floor(raw_cents)::bigint as base_cents,
      row_number() over(
        order by raw_cents-floor(raw_cents) desc,position asc
      ) as priority
    from quota
  ), final_shares as (
    select *,
      base_cents + case when priority <= (
        converted_cents - sum(base_cents) over()
      ) then 1 else 0 end as converted_share_cents
    from allocated
  )
  insert into public.trip_expense_shares
    (expense_id,group_id,user_id,share_amount,share_spending)
  select p_expense,p_group,member_id,original_amount,
    converted_share_cents::numeric/100
  from final_shares;
end; $$;
revoke all on function public._apply_trip_custom_shares(
 uuid,uuid,uuid[],numeric[]) from public,anon,authenticated;

-- Online edits keep all existing author, stale-write and settled-repayment
-- protections from edit_trip_expense. Rollback is atomic on split errors.
create or replace function public.edit_trip_expense_custom(
  p_group uuid,p_expense uuid,p_expected_updated_at timestamptz,
  p_title text,p_amount numeric,p_currency text,p_rate_to_spending numeric,
  p_paid_by uuid,p_members uuid[],p_amounts numeric[],p_date date
) returns void language plpgsql security definer
set search_path = '' as $$
begin
  perform public.edit_trip_expense(
    p_group,p_expense,p_expected_updated_at,p_title,p_amount,p_currency,
    p_rate_to_spending,p_paid_by,p_members,p_date);
  perform public._apply_trip_custom_shares(
    p_group,p_expense,p_members,p_amounts);
end; $$;
revoke all on function public.edit_trip_expense_custom(
 uuid,uuid,timestamptz,text,numeric,text,numeric,uuid,uuid[],numeric[],date)
 from public;
grant execute on function public.edit_trip_expense_custom(
 uuid,uuid,timestamptz,text,numeric,text,numeric,uuid,uuid[],numeric[],date)
 to authenticated;

-- New offline operation RPC, preserving the original immutable UUID semantics.
-- Keep legacy add_trip_expense_offline unchanged for old APKs.
create or replace function public.add_trip_expense_offline_custom(
  p_operation uuid,p_group uuid,p_title text,p_amount numeric,p_currency text,
  p_rate_to_spending numeric,p_paid_by uuid,p_members uuid[],
  p_amounts numeric[],p_date date
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  existing record;
  payload jsonb;
  created uuid;
  locked_group uuid;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Not a group member';
  end if;
  if p_operation is null then raise exception 'Operation ID required'; end if;
  if p_date is not null and
    (p_date < date '1990-01-01' or p_date > current_date+1) then
    raise exception 'Invalid receipt date';
  end if;
  payload:=jsonb_build_object(
    'group_id',p_group,'title',btrim(p_title),'amount',p_amount,
    'currency',p_currency,'rate_to_spending',p_rate_to_spending,
    'paid_by',p_paid_by,'split_between',to_jsonb(p_members),
    'share_amounts',to_jsonb(p_amounts),'receipt_date',p_date);

  select id into locked_group from public.trip_groups
    where id=p_group for update;
  if locked_group is null then raise exception 'Group not found'; end if;
  select * into existing from public.trip_expense_operations
    where operation_id=p_operation;
  if found then
    if existing.created_by != auth.uid() or existing.group_id!=p_group
      or existing.request_payload != payload then
      raise exception 'Operation UUID reused for different details';
    end if;
    if existing.expense_id is null then
      raise exception 'This expense has already been deleted';
    end if;
    return existing.expense_id;
  end if;

  created:=public.add_trip_expense_v2(
    p_group,p_title,p_amount,p_currency,p_rate_to_spending,p_paid_by,p_members);
  perform public._apply_trip_custom_shares(
    p_group,created,p_members,p_amounts);
  update public.trip_expenses set receipt_date=p_date where id=created;
  insert into public.trip_expense_operations(
    operation_id,group_id,created_by,request_payload,expense_id)
  values(p_operation,p_group,auth.uid(),payload,created);
  return created;
end; $$;
revoke all on function public.add_trip_expense_offline_custom(
 uuid,uuid,text,numeric,text,numeric,uuid,uuid[],numeric[],date) from public;
grant execute on function public.add_trip_expense_offline_custom(
 uuid,uuid,text,numeric,text,numeric,uuid,uuid[],numeric[],date)
 to authenticated;
