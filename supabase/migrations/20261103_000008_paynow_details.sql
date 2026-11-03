-- SplitLui Phase 10: opt-in PayNow phone details for each group.
-- Only members of the same group may read these details.
-- Users may add/change/remove only THEIR OWN phone number.
-- No payment generation or bank interaction happens here.

create table if not exists public.trip_paynow_details (
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  mobile text not null check (mobile ~ '^[89][0-9]{7}$'),
  updated_at timestamptz not null default now(),
  primary key (group_id,user_id)
);

alter table public.trip_paynow_details enable row level security;
revoke all on public.trip_paynow_details from anon, authenticated;
grant select on public.trip_paynow_details to authenticated;

drop policy if exists trip_paynow_details_member_read on public.trip_paynow_details;
create policy trip_paynow_details_member_read on public.trip_paynow_details
  for select to authenticated using (public.is_trip_member(group_id));

create or replace function public.set_trip_paynow_mobile(
  p_group uuid, p_mobile text
)
returns void language plpgsql security definer
set search_path = '' as $$
declare
  normalized text;
begin
  if auth.uid() is null or not public.is_trip_member(p_group) then
    raise exception 'Only group members may set PayNow details';
  end if;
  normalized := regexp_replace(coalesce(p_mobile,''), '[[:space:]-]', '', 'g');
  if left(normalized,3) = '+65' then
    normalized := substr(normalized,4);
  elsif left(normalized,2) = '65' and char_length(normalized) = 10 then
    normalized := substr(normalized,3);
  end if;
  if normalized = '' then
    delete from public.trip_paynow_details
      where group_id=p_group and user_id=auth.uid();
    return;
  end if;
  if normalized !~ '^[89][0-9]{7}$' then
    raise exception 'Enter an 8-digit Singapore mobile beginning with 8 or 9';
  end if;
  insert into public.trip_paynow_details(group_id,user_id,mobile)
    values (p_group,auth.uid(),normalized)
    on conflict (group_id,user_id) do update
      set mobile=excluded.mobile,updated_at=now();
end; $$;

revoke all on function public.set_trip_paynow_mobile(uuid,text) from public;
grant execute on function public.set_trip_paynow_mobile(uuid,text)
  to authenticated;
