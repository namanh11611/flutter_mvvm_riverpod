-- Run after migrations 001-004 on a disposable database. All changes roll back.
-- Requires one admin and two ordinary profiles.
begin;
do $$
declare v_admin uuid; v_target uuid; v_reporter uuid; v_report uuid;
  v_count bigint;
begin
  select user_id into v_admin from public.admin_users limit 1;
  select id into v_target from public.user_accounts where id not in (select user_id from public.admin_users) order by id limit 1;
  select id into v_reporter from public.user_accounts where id not in (select user_id from public.admin_users) and id <> v_target order by id limit 1;
  if v_admin is null or v_reporter is null then raise exception 'Requires admin and two user profiles'; end if;
  delete from public.account_bans where user_id in (v_admin,v_target);
  insert into public.user_reports(reporter_id,reported_user_id,reason,description)
    values(v_reporter,v_target,'harassment','Transaction-only case') returning id into v_report;
  if exists(select 1 from public.account_bans where user_id = v_target) then raise exception 'Automatic punishment'; end if;
  begin
    perform public.admin_apply_decision(v_admin,v_target,'warning','Premature',v_report);
    raise exception 'TEST: Skipped review was allowed';
  exception when raise_exception then if sqlerrm like 'TEST:%' then raise; end if;
  end;
  perform public.admin_apply_decision(v_admin,v_target,'start_review','Investigating',v_report);
  select count(*) into v_count from public.moderation_audit where report_id = v_report;
  begin
    perform public.admin_apply_decision(v_admin,v_target,'suspend','Invalid duration',v_report,2);
    raise exception 'TEST: Invalid duration allowed';
  exception when raise_exception then if sqlerrm like 'TEST:%' then raise; end if;
  end;
  if (select status from public.user_reports where id = v_report) <> 'reviewing' or
    (select count(*) from public.moderation_audit where report_id = v_report) <> v_count then raise exception 'Failed action was not atomic'; end if;
  perform public.admin_apply_decision(v_admin,v_target,'suspend','Reviewed evidence',v_report,7);
  if (select status from public.user_reports where id = v_report) <> 'resolved' then raise exception 'Report not resolved'; end if;
  if (select account_status from public.admin_user_summary where id = v_target) <> 'suspended' then raise exception 'Suspension missing'; end if;
  if not exists(select 1 from public.moderation_audit where report_id = v_report and action = 'suspend' and target_id = v_target::text) then raise exception 'Case history missing'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',v_target,'role','authenticated')::text,true);
  if public.account_is_active() or public.get_account_access() <> 'suspended' then raise exception 'Suspension not enforced'; end if;
  perform set_config('request.path','/rpc/get_blocked_users',true);
  begin
    perform public.check_account_access();
    raise exception 'TEST: Suspended RPC allowed';
  exception when sqlstate 'PT403' then null;
  end;
  begin
    perform public.admin_apply_decision(v_admin,v_target,'warning','Duplicate',v_report);
    raise exception 'TEST: Completed report reopened';
  exception when raise_exception then if sqlerrm like 'TEST:%' then raise; end if;
  end;
  update public.account_bans set expires_at = now() - interval '1 second' where user_id = v_target;
  if not public.account_is_active() or public.get_account_access() <> 'user' then raise exception 'Expiry does not restore access'; end if;
  perform public.admin_apply_decision(v_admin,v_target,'warning','Warning recorded');
  if not exists(select 1 from public.moderation_audit where target_id = v_target::text and action = 'warning') then raise exception 'Warning not recorded'; end if;
  perform public.admin_apply_decision(v_admin,v_target,'ban','Serious violation');
  if public.get_account_access() <> 'banned' then raise exception 'Ban not enforced'; end if;
  perform public.admin_apply_decision(v_admin,v_target,'reactivate','Appeal accepted');
  if not public.account_is_active() then raise exception 'Reactivation failed'; end if;
  begin
    perform public.admin_apply_decision(v_target,v_reporter,'ban','Not an administrator');
    raise exception 'TEST: Ordinary user moderated an account';
  exception when raise_exception then if sqlerrm like 'TEST:%' then raise; end if;
  end;
  begin
    perform public.admin_apply_decision(v_admin,v_admin,'ban','Cannot moderate administrator');
    raise exception 'TEST: Administrator account moderated';
  exception when raise_exception then if sqlerrm like 'TEST:%' then raise; end if;
  end;
  insert into public.user_reports(reporter_id,reported_user_id,reason) values(v_reporter,v_target,'other') returning id into v_report;
  perform public.admin_apply_decision(v_admin,v_target,'start_review','Investigating',v_report);
  perform public.admin_apply_decision(v_admin,v_target,'dismiss','Insufficient evidence',v_report);
  if not public.account_is_active() or (select status from public.user_reports where id = v_report) <> 'dismissed' then raise exception 'Dismissal restricted target'; end if;
  if not exists(select 1 from public.admin_search_reports(v_report::text,'dismissed','other')) then raise exception 'Report search failed'; end if;
  if exists(select 1 from public.admin_search_reports(v_report::text,'pending','all')) then raise exception 'Status filter ignored'; end if;
  if not exists(select 1 from public.admin_search_users(v_target::text,'active')) then raise exception 'User search failed'; end if;
  if has_table_privilege('authenticated','public.admin_user_summary','select') or
    has_table_privilege('authenticated','public.admin_report_summary','select') or
    has_function_privilege('authenticated','public.admin_apply_decision(uuid,uuid,text,text,uuid,integer)','execute') or
    has_function_privilege('anon','public.admin_search_users(text,text,integer)','execute') then raise exception 'Admin data exposed'; end if;
end $$;
rollback;
