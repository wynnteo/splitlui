-- Owner-only member management. Apply after migration 000019.
-- Renaming updates group display nickname, not a member's Auth identity.
-- Removing a member is allowed ONLY before any group financial activity
-- involving them, including immutable audit history and zero-value targets.
-- This prevents breaking old balances, repayment history or fund records.

create or replace function public.rename_trip_group_member(
  p_group uuid,p_member uuid,p_nickname text
) returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or not exists(
    select 1 from public.trip_members
    where group_id=p_group and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only group owner can edit members'; end if;
  if p_nickname is null or char_length(btrim(p_nickname)) not between 1 and 60
  then raise exception 'Nickname must be 1-60 characters'; end if;
  update public.trip_members set nickname=btrim(p_nickname)
    where group_id=p_group and user_id=p_member;
  if not found then raise exception 'Member not found'; end if;
end; $$;
revoke all on function public.rename_trip_group_member(uuid,uuid,text)
  from public;
grant execute on function public.rename_trip_group_member(uuid,uuid,text)
  to authenticated;

create or replace function public.remove_trip_group_member(
  p_group uuid,p_member uuid
) returns void language plpgsql security definer
set search_path = '' as $$
declare target_role text;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  -- Acquire group lock to serialize with financial-create RPCs and joins.
  perform 1 from public.trip_groups where id=p_group for update;
  if not found then raise exception 'Group not found'; end if;
  if not exists(
    select 1 from public.trip_members
    where group_id=p_group and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only group owner can remove members'; end if;
  select role into target_role from public.trip_members
    where group_id=p_group and user_id=p_member for update;
  if target_role is null then raise exception 'Member not found'; end if;
  if target_role='owner' then
    raise exception 'The group owner cannot be removed';
  end if;
  if exists(select 1 from public.trip_expenses
      where group_id=p_group and (paid_by=p_member or created_by=p_member))
    or exists(select 1 from public.trip_expense_shares
      where group_id=p_group and user_id=p_member)
    or exists(select 1 from public.trip_repayments
      where group_id=p_group and
        (from_user_id=p_member or to_user_id=p_member or recorded_by=p_member))
    or exists(select 1 from public.trip_fund_entries
      where group_id=p_group and
        (member_id=p_member or recorded_by=p_member))
    or exists(select 1 from public.trip_expense_operations
      where group_id=p_group and created_by=p_member)
    or exists(select 1 from public.trip_receipts
      where group_id=p_group and created_by=p_member)
    or exists(select 1 from public.trip_fund_corrections
      where group_id=p_group and changed_by=p_member)
    or exists(select 1 from public.trip_fund_targets
      where group_id=p_group and
        (member_id=p_member or updated_by=p_member))
    or exists(select 1 from public.trip_fund_topup_requests
      where group_id=p_group and
        (member_id=p_member or created_by=p_member or cancelled_by=p_member))
    or exists(select 1 from public.trip_fund_refunds
      where group_id=p_group and
        (member_id=p_member or confirmed_by=p_member))
  then
    raise exception 'This member has financial records. Keep them for historical accuracy; rename the member instead';
  end if;

  -- Clear private payment contact for the removed member without touching
  -- the account's other groups or other users.
  delete from public.trip_paynow_details
    where group_id=p_group and user_id=p_member;
  delete from public.trip_members
    where group_id=p_group and user_id=p_member and role='member';
  if not found then raise exception 'Member removal failed'; end if;

  -- Someone removed from the group might know the previous invite link.
  -- Invalidate it atomically with membership removal.
  update public.trip_invites set
    token=replace(gen_random_uuid()::text,'-','')||
          replace(gen_random_uuid()::text,'-',''),
    created_at=clock_timestamp()
  where group_id=p_group;
end; $$;
revoke all on function public.remove_trip_group_member(uuid,uuid) from public;
grant execute on function public.remove_trip_group_member(uuid,uuid)
  to authenticated;
