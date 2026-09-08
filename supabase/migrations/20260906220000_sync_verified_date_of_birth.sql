-- The birthday displayed by GoBuddy becomes the value extracted from the
-- approved identity document. It is applied atomically with verification.
drop function if exists public.apply_identity_verification_event(
  text, text, bigint, text, text, text
);

create function public.apply_identity_verification_event(
  p_session_id text, p_event_key text, p_event_at bigint,
  p_provider_status text, p_reason text, p_vendor_data text,
  p_date_of_birth date
)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_attempt public.identity_verifications%rowtype;
  v_latest_id uuid;
  v_status text;
  v_user_id uuid;
begin
  v_status := case p_provider_status
    when 'Approved' then 'verified'
    when 'Declined' then 'unverified' when 'Expired' then 'unverified'
    when 'Abandoned' then 'unverified' when 'Kyc Expired' then 'unverified'
    when 'Not Started' then 'pending' when 'In Progress' then 'pending'
    when 'In Review' then 'pending' when 'Resubmitted' then 'pending'
    when 'Awaiting User' then 'pending' else null end;
  if v_status is null or p_event_at is null or p_event_at < 0 then
    raise exception 'Invalid verification event';
  end if;
  if v_status = 'verified' and p_date_of_birth is null then
    raise exception 'Approved verification requires a document date of birth';
  end if;
  select user_id into v_user_id from public.identity_verifications
    where provider = 'didit' and provider_session_id = p_session_id;
  if not found then return 'unknown_session'; end if;
  if p_vendor_data is not null and p_vendor_data <> v_user_id::text then
    raise exception 'Verification user mismatch';
  end if;
  perform 1 from public.user_accounts where id = v_user_id for update;
  select * into v_attempt from public.identity_verifications
    where provider = 'didit' and provider_session_id = p_session_id for update;
  insert into public.identity_verification_events(event_key) values(p_event_key)
    on conflict do nothing;
  if not found then return 'duplicate'; end if;
  select id into v_latest_id from public.identity_verifications
    where user_id = v_user_id and provider = 'didit'
    order by submitted_at desc, id desc limit 1;
  if v_latest_id <> v_attempt.id then return 'superseded'; end if;
  if p_event_at < v_attempt.last_event_at or
    (p_event_at = v_attempt.last_event_at and v_attempt.status <> 'pending' and v_status = 'pending') then
    return 'stale';
  end if;
  update public.identity_verifications set status = v_status,
    provider_status = p_provider_status, last_event_at = p_event_at,
    rejection_reason = case when p_provider_status = 'Declined' then left(p_reason, 1000) else null end
    where id = v_attempt.id;
  update public.user_accounts set
    verification_status = v_status,
    date_of_birth = case when v_status = 'verified' then p_date_of_birth else date_of_birth end,
    updated_at = now()
    where id = v_user_id and (
      verification_status is distinct from v_status or
      (v_status = 'verified' and date_of_birth is distinct from p_date_of_birth)
    );
  return 'applied';
end $$;

revoke all on function public.apply_identity_verification_event(
  text, text, bigint, text, text, text, date
) from public, anon, authenticated;
grant execute on function public.apply_identity_verification_event(
  text, text, bigint, text, text, text, date
) to service_role;
