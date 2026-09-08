-- Account and attempt statuses use the same three application values. Keep the
-- provider's more detailed lifecycle separately, for webhook ordering/retries.
create table if not exists public.identity_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  provider text not null default 'didit',
  provider_session_id text not null,
  status text not null default 'pending',
  submitted_at timestamptz not null default now()
);
alter table public.identity_verifications
  add column if not exists provider_status text,
  add column if not exists verification_url text,
  add column if not exists rejection_reason text,
  add column if not exists last_event_at bigint not null default 0;

-- Older installations used Didit lifecycle values in this column.
do $$
declare c record;
begin
  for c in select conname from pg_constraint
    where conrelid = 'public.identity_verifications'::regclass
      and contype = 'c' and pg_get_constraintdef(oid) ~ '\mstatus\M'
  loop
    execute format('alter table public.identity_verifications drop constraint %I', c.conname);
  end loop;
end $$;
update public.identity_verifications
set provider_status = coalesce(provider_status, status),
    status = case lower(status)
      when 'approved' then 'verified' when 'verified' then 'verified'
      when 'declined' then 'unverified' when 'rejected' then 'unverified'
      when 'expired' then 'unverified' when 'abandoned' then 'unverified'
      when 'kyc expired' then 'unverified' when 'unverified' then 'unverified'
      else 'pending' end;
alter table public.identity_verifications alter column status set default 'pending';
alter table public.identity_verifications add constraint identity_verification_app_status
  check (status in ('unverified', 'pending', 'verified'));
create unique index if not exists identity_verification_provider_session
  on public.identity_verifications(provider, provider_session_id);
create index if not exists identity_verification_user_latest
  on public.identity_verifications(user_id, submitted_at desc);

-- A short lease prevents parallel taps/devices from creating duplicate sessions.
create table public.identity_verification_starts (
  user_id uuid primary key references public.user_accounts(id) on delete cascade,
  token uuid not null,
  started_at timestamptz not null default now()
);
create table public.identity_verification_events (
  event_key text primary key,
  received_at timestamptz not null default now()
);
alter table public.identity_verifications enable row level security;
alter table public.identity_verification_starts enable row level security;
alter table public.identity_verification_events enable row level security;
revoke all on public.identity_verifications, public.identity_verification_starts,
  public.identity_verification_events from anon, authenticated;
grant all on public.identity_verifications, public.identity_verification_starts,
  public.identity_verification_events to service_role;

-- Profile editing must never allow users to grant themselves verification.
create or replace function public.protect_identity_verification_status()
returns trigger language plpgsql set search_path = '' as $$
begin
  if coalesce(auth.role(), '') in ('anon', 'authenticated') then
    if (tg_op = 'INSERT' and new.verification_status <> 'unverified') or
       (tg_op = 'UPDATE' and new.verification_status is distinct from old.verification_status) then
      raise exception 'Verification status can only be changed by the verification service'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;
create trigger protect_identity_verification_status
before insert or update on public.user_accounts
for each row execute function public.protect_identity_verification_status();

alter table public.matchmaking_notifications alter column trip_id drop not null;
alter table public.matchmaking_notifications
  add column if not exists metadata jsonb not null default '{}'::jsonb;

-- The inbox insert participates in the same transaction as the status update.
-- Its existing INSERT webhook also delivers the notification through FCM.
create or replace function public.notify_identity_verification_status()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_attempt public.identity_verifications%rowtype;
  v_title text;
  v_body text;
begin
  if new.verification_status is not distinct from old.verification_status then
    return new;
  end if;
  select * into v_attempt from public.identity_verifications
    where user_id = new.id order by submitted_at desc, id desc limit 1;
  case new.verification_status
    when 'pending' then
      v_title := 'Identity verification pending';
      v_body := 'Your identity verification has started. Complete any remaining steps in Didit. We will notify you when a result is available.';
    when 'verified' then
      v_title := 'Identity verified';
      v_body := 'Your identity verification was approved. Your profile now shows your verified badge.';
    else
      if v_attempt.provider_status = 'Declined' then
        v_title := 'Identity verification rejected';
        v_body := 'Your verification was rejected. Reason: ' ||
          coalesce(nullif(v_attempt.rejection_reason, ''), 'Didit did not provide a reason. Please contact support for details.') ||
          ' Your status is unverified. Open Verify Identity to try again.';
      elsif v_attempt.provider_status in ('Expired', 'Abandoned', 'Kyc Expired') then
        v_title := 'Identity verification needs to be completed again';
        v_body := 'Your verification expired or was not completed in time. Your status is unverified. Open Verify Identity to try again.';
      else
        v_title := 'Identity verification updated';
        v_body := 'Your identity verification status is now unverified. Open Verify Identity to continue.';
      end if;
  end case;
  insert into public.matchmaking_notifications(user_id, trip_id, title, body, metadata)
  values (new.id, null, v_title, v_body, jsonb_build_object(
    'type', 'identity_verification', 'verification_status', new.verification_status,
    'reason', case when v_attempt.provider_status = 'Declined' then v_attempt.rejection_reason else null end));
  return new;
end $$;
create trigger notify_identity_verification_status
after update of verification_status on public.user_accounts
for each row execute function public.notify_identity_verification_status();

create or replace function public.reserve_identity_verification(p_user_id uuid, p_token uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_status text;
  v_attempt public.identity_verifications%rowtype;
begin
  select verification_status into v_status from public.user_accounts
    where id = p_user_id for update;
  if not found then raise exception 'Profile not found'; end if;
  if v_status = 'verified' then return jsonb_build_object('action', 'verified'); end if;
  select * into v_attempt from public.identity_verifications
    where user_id = p_user_id and provider = 'didit'
    order by submitted_at desc, id desc limit 1;
  if v_attempt.status = 'pending' and v_attempt.verification_url is not null then
    update public.user_accounts set verification_status = 'pending', updated_at = now()
      where id = p_user_id and verification_status <> 'pending';
    return jsonb_build_object('action', 'reuse', 'session_id', v_attempt.provider_session_id,
      'verification_url', v_attempt.verification_url, 'status', 'pending');
  end if;
  insert into public.identity_verification_starts(user_id, token) values(p_user_id, p_token)
    on conflict(user_id) do update set token = excluded.token, started_at = now()
      where public.identity_verification_starts.started_at < now() - interval '2 minutes';
  if not found then return jsonb_build_object('action', 'busy'); end if;
  return jsonb_build_object('action', 'create');
end $$;

create or replace function public.finish_identity_verification_start(
  p_user_id uuid, p_token uuid, p_session_id text, p_url text
)
returns void language plpgsql security definer set search_path = '' as $$
declare v_status text;
begin
  select verification_status into v_status from public.user_accounts where id = p_user_id for update;
  if v_status = 'verified' then raise exception 'Your identity is already verified'; end if;
  delete from public.identity_verification_starts where user_id = p_user_id and token = p_token;
  if not found then raise exception 'Verification request expired. Please retry.'; end if;
  insert into public.identity_verifications(user_id, provider, provider_session_id,
    verification_url, status, provider_status, submitted_at)
  values(p_user_id, 'didit', p_session_id, p_url, 'pending', 'Not Started', clock_timestamp());
  update public.user_accounts set verification_status = 'pending', updated_at = now()
    where id = p_user_id;
end $$;

create or replace function public.apply_identity_verification_event(
  p_session_id text, p_event_key text, p_event_at bigint,
  p_provider_status text, p_reason text, p_vendor_data text
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
  select user_id into v_user_id from public.identity_verifications
    where provider = 'didit' and provider_session_id = p_session_id;
  -- A callback can arrive between provider creation and saving the session.
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
  update public.user_accounts set verification_status = v_status, updated_at = now()
    where id = v_user_id and verification_status is distinct from v_status;
  return 'applied';
end $$;

revoke all on function public.reserve_identity_verification(uuid, uuid) from public, anon, authenticated;
revoke all on function public.finish_identity_verification_start(uuid, uuid, text, text) from public, anon, authenticated;
revoke all on function public.apply_identity_verification_event(text, text, bigint, text, text, text) from public, anon, authenticated;
grant execute on function public.reserve_identity_verification(uuid, uuid) to service_role;
grant execute on function public.finish_identity_verification_start(uuid, uuid, text, text) to service_role;
grant execute on function public.apply_identity_verification_event(text, text, bigint, text, text, text) to service_role;
