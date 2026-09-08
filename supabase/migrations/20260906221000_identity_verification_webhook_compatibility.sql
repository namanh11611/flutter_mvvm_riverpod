-- Keep the previous webhook version callable during a rolling Edge Function
-- deployment. Approved events fail/retry until the new webhook supplies DOB.
create or replace function public.apply_identity_verification_event(
  p_session_id text, p_event_key text, p_event_at bigint,
  p_provider_status text, p_reason text, p_vendor_data text
)
returns text language sql security definer set search_path = '' as $$
  select public.apply_identity_verification_event(
    p_session_id, p_event_key, p_event_at, p_provider_status,
    p_reason, p_vendor_data, null::date
  );
$$;

revoke all on function public.apply_identity_verification_event(
  text, text, bigint, text, text, text
) from public, anon, authenticated;
grant execute on function public.apply_identity_verification_event(
  text, text, bigint, text, text, text
) to service_role;

