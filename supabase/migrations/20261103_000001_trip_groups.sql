-- SplitLui Phase 2: collaborative group foundations.
-- Run in the Supabase SQL editor. Requires pgcrypto and anonymous Auth enabled.
create extension if not exists pgcrypto;

create table if not exists public.trip_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  is_travel boolean not null default true,
  spending_currency text not null check (spending_currency ~ '^[A-Z]{3}$'),
  settlement_currency text not null check (settlement_currency ~ '^[A-Z]{3}$'),
  exchange_rate numeric(22,8) not null check (exchange_rate > 0),
  budget numeric(18,2) check (budget is null or budget >= 0),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.trip_members (
  group_id uuid not null references public.trip_groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  nickname text not null check (char_length(btrim(nickname)) between 1 and 60),
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);
create index if not exists trip_members_user_idx on public.trip_members(user_id);

-- Only a security-definer function reads this table, never the client.
create table if not exists public.trip_invites (
  group_id uuid primary key references public.trip_groups(id) on delete cascade,
  token text unique not null,
  created_at timestamptz not null default now()
);

alter table public.trip_groups enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_invites enable row level security;

revoke all on public.trip_groups, public.trip_members, public.trip_invites from anon;
revoke all on public.trip_groups, public.trip_members, public.trip_invites from authenticated;
grant select on public.trip_groups, public.trip_members to authenticated;

-- SECURITY DEFINER avoids recursive RLS checks when testing group membership.
create or replace function public.is_trip_member(p_group uuid)
returns boolean language sql stable security definer
set search_path = '' as $$
  select exists (
    select 1 from public.trip_members
    where group_id = p_group and user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_trip_member(uuid) from public;
grant execute on function public.is_trip_member(uuid) to authenticated;

drop policy if exists trip_groups_member_read on public.trip_groups;
create policy trip_groups_member_read on public.trip_groups
  for select to authenticated using (public.is_trip_member(id));

drop policy if exists trip_members_member_read on public.trip_members;
create policy trip_members_member_read on public.trip_members
  for select to authenticated using (public.is_trip_member(group_id));

-- A single RPC atomically creates the group, owner membership, and secret invite.
create or replace function public.create_trip_group(
  p_name text, p_is_travel boolean, p_spending text, p_settlement text,
  p_rate numeric, p_budget numeric, p_nickname text
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  new_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_nickname is null or char_length(btrim(p_nickname)) not between 1 and 60
     then raise exception 'Invalid nickname'; end if;
  insert into public.trip_groups
    (name,is_travel,spending_currency,settlement_currency,exchange_rate,budget,created_by)
    values (btrim(p_name),p_is_travel,p_spending,p_settlement,p_rate,p_budget,auth.uid())
    returning id into new_id;
  insert into public.trip_members(group_id,user_id,nickname,role)
    values (new_id,auth.uid(),btrim(p_nickname),'owner');
  insert into public.trip_invites(group_id,token)
    values(new_id, replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-',''));
  return new_id;
end; $$;
revoke all on function public.create_trip_group(text,boolean,text,text,numeric,numeric,text) from public;
grant execute on function public.create_trip_group(text,boolean,text,text,numeric,numeric,text) to authenticated;

-- Use a high-entropy token, not a short predictable six-digit code.
create or replace function public.join_trip_group(p_token text,p_nickname text)
returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  found_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_nickname is null or char_length(btrim(p_nickname)) not between 1 and 60
    then raise exception 'Invalid nickname'; end if;
  select group_id into found_id from public.trip_invites
    where token = lower(btrim(p_token));
  if found_id is null then raise exception 'Invalid invitation code'; end if;
  insert into public.trip_members(group_id,user_id,nickname,role)
    values (found_id,auth.uid(),btrim(p_nickname),'member')
    on conflict (group_id,user_id) do nothing;
  return found_id;
end; $$;
revoke all on function public.join_trip_group(text,text) from public;
grant execute on function public.join_trip_group(text,text) to authenticated;

create or replace function public.get_trip_invite(p_group uuid)
returns text language plpgsql stable security definer
set search_path = '' as $$
declare token_value text;
begin
  if not public.is_trip_member(p_group) then raise exception 'Not a group member'; end if;
  select token into token_value from public.trip_invites where group_id=p_group;
  return token_value;
end; $$;
revoke all on function public.get_trip_invite(uuid) from public;
grant execute on function public.get_trip_invite(uuid) to authenticated;

create or replace function public.rotate_trip_invite(p_group uuid)
returns text language plpgsql security definer
set search_path = '' as $$
declare new_token text;
begin
  if not exists (
    select 1 from public.trip_members
    where group_id=p_group and user_id=auth.uid() and role='owner'
  ) then raise exception 'Only the owner can reset invitations'; end if;
  new_token := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
  update public.trip_invites set token=new_token,created_at=now() where group_id=p_group;
  return new_token;
end; $$;
revoke all on function public.rotate_trip_invite(uuid) from public;
grant execute on function public.rotate_trip_invite(uuid) to authenticated;

-- Never put the service_role key in Flutter or grant direct reads of trip_invites.
