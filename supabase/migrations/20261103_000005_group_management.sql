-- Phase 6: unified group management, owner-only editing and deletion.
-- Run after the Phase 2 group schema. Existing data is unaffected.
-- A group cannot change currency units after creation; amounts in the
-- expense and common fund ledgers are denominated in spending currency.

create or replace function public.update_trip_group(
  p_group uuid, p_name text, p_is_travel boolean,
  p_rate numeric, p_budget numeric
) returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = auth.uid() and role = 'owner'
  ) then raise exception 'Only the group owner can edit this group'; end if;
  if p_name is null or char_length(btrim(p_name)) not between 1 and 120 then
    raise exception 'Invalid group name'; end if;
  if p_is_travel is null then raise exception 'Invalid group type'; end if;
  if p_rate is null or p_rate <= 0 or p_rate > 99999999999999
    then raise exception 'Invalid exchange rate'; end if;
  if p_budget is not null and (p_budget < 0 or p_budget > 9999999999999999.99
    or p_budget != round(p_budget,2)) then
    raise exception 'Invalid budget'; end if;

  update public.trip_groups set
    name = btrim(p_name), is_travel = p_is_travel,
    exchange_rate = p_rate, budget = p_budget
  where id = p_group;
end; $$;
revoke all on function public.update_trip_group(uuid,text,boolean,numeric,numeric) from public;
grant execute on function public.update_trip_group(uuid,text,boolean,numeric,numeric) to authenticated;

-- Deleting a group permanently removes all its children through FK CASCADE.
-- Require the caller to retype the *current* group name to prevent accidental
-- deletion; the owner is the only one allowed to perform this action.
create or replace function public.delete_trip_group(
  p_group uuid, p_confirm_name text
) returns void language plpgsql security definer
set search_path = '' as $$
declare current_name text;
begin
  if auth.uid() is null or not exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = auth.uid() and role = 'owner'
  ) then raise exception 'Only the group owner can delete this group'; end if;

  select name into current_name from public.trip_groups
    where id = p_group for update;
  if current_name is null then raise exception 'Group not found'; end if;
  if p_confirm_name is null or btrim(p_confirm_name) != current_name then
    raise exception 'Confirmation name does not match'; end if;

  delete from public.trip_groups where id = p_group;
end; $$;
revoke all on function public.delete_trip_group(uuid,text) from public;
grant execute on function public.delete_trip_group(uuid,text) to authenticated;
