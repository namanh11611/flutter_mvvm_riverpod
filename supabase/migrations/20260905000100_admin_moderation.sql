-- Roles are provisioned by an operator, never by email matching in the app.
create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table public.account_bans (
  user_id uuid primary key references auth.users(id) on delete cascade,
  reason text not null check (length(trim(reason)) between 1 and 1000),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);
create table public.moderation_audit (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id),
  action text not null,
  target_id text not null,
  reason text not null,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
alter table public.account_bans enable row level security;
alter table public.moderation_audit enable row level security;
revoke all on public.admin_users, public.account_bans, public.moderation_audit from anon, authenticated;
grant all on public.admin_users, public.account_bans, public.moderation_audit to service_role;
grant usage, select on sequence public.moderation_audit_id_seq to service_role;

create function public.account_is_active() returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists(select 1 from public.account_bans where user_id = auth.uid());
$$;
create function public.get_account_access() returns text
language sql stable security definer set search_path = '' as $$
  select case when auth.uid() is null then 'anonymous'
    when not public.account_is_active() then 'banned'
    when exists(select 1 from public.admin_users where user_id = auth.uid()) then 'admin'
    else 'user' end;
$$;
revoke all on function public.account_is_active(), public.get_account_access() from public;
grant execute on function public.account_is_active(), public.get_account_access() to authenticated;

-- Restrictive policies also cover Storage and Realtime table access.
do $$ declare t record; begin
  for t in select schemaname, tablename from pg_tables
    where (schemaname = 'public' and rowsecurity)
       or (schemaname = 'storage' and tablename = 'objects')
  loop
    execute format('create policy account_must_be_active on %I.%I as restrictive for all to authenticated using ((select public.account_is_active())) with check ((select public.account_is_active()))', t.schemaname, t.tablename);
  end loop;
end $$;

-- Covers security-definer RPCs that bypass table RLS, including existing JWTs.
create function public.check_account_access() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is not null and not public.account_is_active()
     and coalesce(current_setting('request.path', true), '') <> '/rpc/get_account_access' then
    raise sqlstate 'PT403' using message = 'Your account has been banned.';
  end if;
end;
$$;
revoke all on function public.check_account_access() from public;
grant execute on function public.check_account_access() to anon, authenticated, service_role;
alter role authenticator set pgrst.db_pre_request = 'public.check_account_access';
notify pgrst, 'reload config';

-- Reporters must not be able to submit a pre-resolved report or forge a reviewer.
drop policy if exists "users create their reports" on public.user_reports;
create policy "users create their reports" on public.user_reports for insert to authenticated
with check (reporter_id = auth.uid() and status = 'pending' and reviewed_at is null and reviewed_by is null);
