-- Keep a report transition and its internal review note in one transaction.
create or replace function public.admin_review_report(
  p_report_id uuid, p_actor_id uuid, p_status text, p_reason text
) returns void language plpgsql security definer set search_path = '' as $$
declare current_status text;
begin
  if not exists(select 1 from public.admin_users where user_id = p_actor_id)
    or exists(select 1 from public.account_bans where user_id = p_actor_id) then
    raise exception 'Admin access required';
  end if;
  if p_reason is null or length(trim(p_reason)) not between 1 and 1000 then
    raise exception 'A review note is required';
  end if;
  select status into current_status from public.user_reports where id = p_report_id for update;
  if current_status is null or p_status is null or not (
    (current_status = 'pending' and p_status = 'reviewing') or
    (current_status = 'reviewing' and p_status in ('resolved', 'dismissed'))
  ) then raise exception 'Invalid report transition. Refresh the report.'; end if;
  update public.user_reports set status = p_status, reviewed_by = p_actor_id,
    reviewed_at = now() where id = p_report_id;
  insert into public.moderation_audit(actor_id, action, target_id, reason)
  values(p_actor_id, 'review', p_report_id::text,
    json_build_object('reason', trim(p_reason), 'old_status', current_status, 'status', p_status)::text);
end;
$$;
revoke all on function public.admin_review_report(uuid, uuid, text, text) from public, anon, authenticated;
grant execute on function public.admin_review_report(uuid, uuid, text, text) to service_role;
