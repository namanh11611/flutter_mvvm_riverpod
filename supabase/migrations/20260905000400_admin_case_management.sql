-- Extend the existing restriction record; null expiry remains a permanent ban.
alter table public.account_bans add column expires_at timestamptz;
alter table public.moderation_audit add column report_id uuid references public.user_reports(id);
create index moderation_audit_target_idx on public.moderation_audit(target_id, created_at);
create index moderation_audit_report_idx on public.moderation_audit(report_id, created_at);

create or replace function public.account_is_active() returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists(select 1 from public.account_bans where user_id = auth.uid()
    and (expires_at is null or expires_at > now()));
$$;
create or replace function public.get_account_access() returns text
language sql stable security definer set search_path = '' as $$
  select case when auth.uid() is null then 'anonymous'
    when exists(select 1 from public.account_bans where user_id = auth.uid() and expires_at is null) then 'banned'
    when not public.account_is_active() then 'suspended'
    when exists(select 1 from public.admin_users where user_id = auth.uid()) then 'admin'
    else 'user' end;
$$;
create or replace function public.check_account_access() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is not null and not public.account_is_active()
    and coalesce(current_setting('request.path', true), '') <> '/rpc/get_account_access' then
    raise sqlstate 'PT403' using message = 'Your account is restricted.';
  end if;
end;
$$;

-- Views are accessible only through the server's service role.
create view public.admin_user_summary as
select u.id, u.display_name, a.email, u.profile_photo_path,
  exists(select 1 from public.admin_users x where x.user_id = u.id) as is_admin,
  case when b.user_id is null then 'active' when b.expires_at is null then 'banned'
    else 'suspended' end as account_status,
  b.expires_at as suspended_until, b.reason as restriction_reason,
  (select count(*) from public.user_reports r where r.reported_user_id = u.id) as report_count,
  (select count(*) from public.moderation_audit m where m.target_id = u.id::text and m.action = 'warning') as warning_count,
  (select count(*) from public.moderation_audit m where m.target_id = u.id::text and m.action = 'suspend') as suspension_count
from public.user_accounts u join auth.users a on a.id = u.id
left join public.account_bans b on b.user_id = u.id and (b.expires_at is null or b.expires_at > now());
create view public.admin_report_summary as
select r.*, reporter.display_name as reporter_name, target.display_name as reported_user_name,
  target.account_status, target.is_admin as target_is_admin, target.report_count - 1 as previous_reports,
  target.warning_count, target.suspended_until
from public.user_reports r
left join public.user_accounts reporter on reporter.id = r.reporter_id
left join public.admin_user_summary target on target.id = r.reported_user_id;
revoke all on public.admin_user_summary, public.admin_report_summary from public, anon, authenticated;
grant select on public.admin_user_summary, public.admin_report_summary to service_role;

create function public.admin_search_reports(p_search text default '', p_status text default 'all',
  p_category text default 'all', p_since timestamptz default null, p_oldest boolean default false,
  p_page integer default 0) returns setof public.admin_report_summary
language sql stable security definer set search_path = '' as $$
  select r.* from public.admin_report_summary r
  where (p_status = 'all' or r.status = p_status)
    and (p_category = 'all' or r.reason = p_category)
    and (p_since is null or r.created_at >= p_since)
    and (p_search = '' or strpos(lower(concat_ws(' ', r.id, r.reporter_id, r.reported_user_id,
      r.reporter_name, r.reported_user_name)), lower(p_search)) > 0)
  order by case when p_oldest then r.created_at end asc,
    case when not p_oldest then r.created_at end desc, r.id
  limit 50 offset greatest(p_page, 0) * 50;
$$;
create function public.admin_search_users(p_search text default '', p_status text default 'all',
  p_page integer default 0) returns setof public.admin_user_summary
language sql stable security definer set search_path = '' as $$
  select u.* from public.admin_user_summary u
  where (p_status = 'all' or u.account_status = p_status)
    and (p_search = '' or strpos(lower(concat_ws(' ', u.id, u.display_name, u.email)), lower(p_search)) > 0)
  order by lower(u.display_name), u.id limit 50 offset greatest(p_page, 0) * 50;
$$;
revoke all on function public.admin_search_reports(text,text,text,timestamptz,boolean,integer),
  public.admin_search_users(text,text,integer) from public, anon, authenticated;
grant execute on function public.admin_search_reports(text,text,text,timestamptz,boolean,integer),
  public.admin_search_users(text,text,integer) to service_role;

-- Restrictions, decisions and history commit together. Account access is enforced
-- by the existing RLS policies/pre-request hook, including already-issued JWTs.
create function public.admin_apply_decision(p_actor_id uuid, p_target_id uuid, p_action text,
  p_reason text, p_report_id uuid default null, p_days integer default null) returns void
language plpgsql security definer set search_path = '' as $$
declare r public.user_reports; old_status text; expiry timestamptz;
begin
  if not exists(select 1 from public.admin_users where user_id = p_actor_id)
    or exists(select 1 from public.account_bans where user_id = p_actor_id
      and (expires_at is null or expires_at > now())) then raise exception 'Admin access required'; end if;
  if p_reason is null or length(trim(p_reason)) not between 1 and 1000 then raise exception 'Enter an internal note'; end if;
  if p_action is null or p_action not in ('start_review','dismiss','no_action','warning','suspend','ban','reactivate') then
    raise exception 'Invalid decision'; end if;
  if p_report_id is not null then
    select * into r from public.user_reports where id = p_report_id for update;
    if not found or r.reported_user_id <> p_target_id then raise exception 'Report not found'; end if;
    if (p_action = 'start_review' and r.status <> 'pending') or
      (p_action <> 'start_review' and r.status <> 'reviewing') or p_action = 'reactivate' then
      raise exception 'Report changed. Refresh before deciding.'; end if;
  elsif p_action in ('start_review','dismiss','no_action') then raise exception 'A report is required';
  end if;
  -- Lock the target so concurrent moderation decisions cannot overwrite blindly.
  perform 1 from public.user_accounts where id = p_target_id for update;
  if not found then raise exception 'User not found'; end if;
  select account_status into old_status from public.admin_user_summary where id = p_target_id;
  if p_action in ('warning','suspend','ban','reactivate') then
    if exists(select 1 from public.admin_users where user_id = p_target_id) then raise exception 'Admin accounts cannot be moderated'; end if;
    if (p_action in ('warning','suspend') and old_status <> 'active') or
      (p_action = 'ban' and old_status = 'banned') or
      (p_action = 'reactivate' and old_status = 'active') then raise exception 'Account status changed. Refresh before deciding.'; end if;
  end if;
  if p_action = 'suspend' then
    if p_days is null or p_days not in (1,3,7,30) then raise exception 'Invalid suspension duration'; end if;
    expiry := now() + make_interval(days => p_days);
  end if;
  if p_action in ('suspend','ban') then
    insert into public.account_bans(user_id, reason, created_by, expires_at)
    values(p_target_id, trim(p_reason), p_actor_id, expiry)
    on conflict(user_id) do update set reason = excluded.reason, created_by = excluded.created_by,
      created_at = now(), expires_at = excluded.expires_at;
  elsif p_action = 'reactivate' then delete from public.account_bans where user_id = p_target_id;
  end if;
  if p_report_id is not null then
    update public.user_reports set status = case when p_action = 'start_review' then 'reviewing'
      when p_action = 'dismiss' then 'dismissed' else 'resolved' end,
      reviewed_by = p_actor_id, reviewed_at = now() where id = p_report_id;
  end if;
  insert into public.moderation_audit(actor_id, action, target_id, report_id, reason)
  values(p_actor_id, p_action, p_target_id::text, p_report_id,
    json_build_object('reason', trim(p_reason), 'old_status', old_status,
      'days', p_days, 'suspended_until', expiry,
      'old_report_status', r.status,
      'report_status', case when p_report_id is null then null
        when p_action = 'start_review' then 'reviewing'
        when p_action = 'dismiss' then 'dismissed' else 'resolved' end)::text);
end;
$$;
revoke all on function public.admin_apply_decision(uuid,uuid,text,text,uuid,integer) from public, anon, authenticated;
grant execute on function public.admin_apply_decision(uuid,uuid,text,text,uuid,integer) to service_role;
