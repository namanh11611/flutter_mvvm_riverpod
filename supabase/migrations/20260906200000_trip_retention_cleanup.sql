-- Delete trips seven days after they end and queue their Storage directories
-- for deletion through the Storage API.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- A queue is deliberately kept outside the trip foreign-key graph. It must
-- survive the trip cascade so an Edge Function can remove the corresponding
-- Storage objects after the database transaction commits.
create table if not exists public.trip_storage_cleanup_queue (
  trip_id uuid primary key,
  owner_id uuid not null,
  queued_at timestamptz not null default now(),
  attempts integer not null default 0,
  last_error text,
  last_attempt_at timestamptz
);

alter table public.trip_storage_cleanup_queue enable row level security;
revoke all on table public.trip_storage_cleanup_queue from public, anon, authenticated;
grant select, update, delete on table public.trip_storage_cleanup_queue
  to service_role;

-- Repair any existing direct foreign key to matchmaking_trips that may have
-- been created without ON DELETE CASCADE in an older or manually edited
-- environment. All current migrations already create these constraints with
-- CASCADE; this block also protects drifted databases.
do $$
declare
  v_constraint record;
  v_definition text;
begin
  for v_constraint in
    select c.oid, c.conrelid, c.conname
    from pg_constraint c
    where c.contype = 'f'
      and c.confrelid = 'public.matchmaking_trips'::regclass
      and c.confdeltype <> 'c'
  loop
    v_definition := pg_get_constraintdef(v_constraint.oid);
    v_definition := regexp_replace(
      v_definition,
      ' ON DELETE (NO ACTION|RESTRICT|CASCADE|SET NULL|SET DEFAULT)',
      '',
      'i'
    );

    if v_definition ~* ' (NOT )?DEFERRABLE' then
      v_definition := regexp_replace(
        v_definition,
        ' ((NOT )?DEFERRABLE)',
        ' ON DELETE CASCADE \1',
        'i'
      );
    else
      v_definition := v_definition || ' ON DELETE CASCADE';
    end if;

    execute format(
      'alter table %s drop constraint %I',
      v_constraint.conrelid::regclass,
      v_constraint.conname
    );
    execute format(
      'alter table %s add constraint %I %s',
      v_constraint.conrelid::regclass,
      v_constraint.conname,
      v_definition
    );
  end loop;
end;
$$;

create or replace function public.cleanup_expired_matchmaking_trips()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted_count integer;
begin
  with candidates as materialized (
    select trip.id, trip.owner_id
    from public.matchmaking_trips trip
    where trip.end_date < current_date - interval '7 days'
    for update skip locked
  ),
  queued as (
    insert into public.trip_storage_cleanup_queue (trip_id, owner_id)
    select candidate.id, candidate.owner_id
    from candidates candidate
    on conflict (trip_id) do update set
      owner_id = excluded.owner_id,
      queued_at = now(),
      last_error = null
    returning trip_id
  ),
  deleted as (
    delete from public.matchmaking_trips trip
    using queued
    where trip.id = queued.trip_id
      and trip.end_date < current_date - interval '7 days'
    returning trip.id
  )
  select count(*)::integer into v_deleted_count from deleted;

  return v_deleted_count;
end;
$$;

revoke all on function public.cleanup_expired_matchmaking_trips()
  from public, anon, authenticated;
grant execute on function public.cleanup_expired_matchmaking_trips()
  to service_role;

-- Delete eligible database rows first, then ask the Edge Function to drain the
-- durable Storage cleanup queue. The queue makes retries safe if HTTP or
-- Storage is temporarily unavailable.
create or replace function public.run_expired_trip_cleanup_job()
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_deleted_count integer;
  v_project_url text;
  v_anon_key text;
begin
  v_deleted_count := public.cleanup_expired_matchmaking_trips();

  select decrypted_secret into v_project_url
  from vault.decrypted_secrets
  where name = 'project_url'
  limit 1;

  select decrypted_secret into v_anon_key
  from vault.decrypted_secrets
  where name = 'anon_key'
  limit 1;

  if nullif(trim(v_project_url), '') is null
      or nullif(trim(v_anon_key), '') is null then
    raise warning 'Trip rows were cleaned, but Storage cleanup was queued: Vault secrets project_url and anon_key are required';
    return v_deleted_count;
  end if;

  perform net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/cleanup-expired-trips',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', v_anon_key,
      'Authorization', 'Bearer ' || v_anon_key
    ),
    body := jsonb_build_object('source', 'pg_cron'),
    timeout_milliseconds := 120000
  );

  return v_deleted_count;
end;
$$;

revoke all on function public.run_expired_trip_cleanup_job()
  from public, anon, authenticated;
grant execute on function public.run_expired_trip_cleanup_job()
  to service_role;

do $$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobid
    from cron.job
    where jobname = 'cleanup-expired-trips-daily'
  loop
    perform cron.unschedule(v_job_id);
  end loop;

  -- Run every day at 12:00 UTC (20:00 Asia/Singapore).
  perform cron.schedule(
    'cleanup-expired-trips-daily',
    '0 12 * * *',
    'select public.run_expired_trip_cleanup_job();'
  );
end;
$$;

comment on function public.cleanup_expired_matchmaking_trips() is
  'Deletes trips whose end_date is more than seven days ago; child rows cascade and Storage cleanup is queued.';

notify pgrst, 'reload schema';
