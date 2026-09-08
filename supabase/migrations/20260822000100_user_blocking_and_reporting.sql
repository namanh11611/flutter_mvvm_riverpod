-- Safety: durable user blocks and moderation reports.
create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_not_self check (blocker_id <> blocked_id)
);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in (
    'harassment', 'hateSpeech', 'inappropriateContent', 'scam',
    'impersonation', 'other'
  )),
  description text check (description is null or char_length(description) <= 1000),
  status text not null default 'pending'
    check (status in ('pending', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  constraint user_reports_not_self check (reporter_id <> reported_user_id)
);

create index if not exists user_blocks_blocked_idx
  on public.user_blocks(blocked_id);
create index if not exists user_reports_review_queue_idx
  on public.user_reports(status, created_at);

alter table public.user_blocks enable row level security;
alter table public.user_reports enable row level security;

drop policy if exists "users read blocks they created" on public.user_blocks;
create policy "users read blocks they created" on public.user_blocks
  for select to authenticated using (blocker_id = auth.uid());
drop policy if exists "users create their blocks" on public.user_blocks;
create policy "users create their blocks" on public.user_blocks
  for insert to authenticated with check (blocker_id = auth.uid());
drop policy if exists "users remove their blocks" on public.user_blocks;
create policy "users remove their blocks" on public.user_blocks
  for delete to authenticated using (blocker_id = auth.uid());
drop policy if exists "users create their reports" on public.user_reports;
create policy "users create their reports" on public.user_reports
  for insert to authenticated with check (reporter_id = auth.uid());
drop policy if exists "users read their reports" on public.user_reports;
create policy "users read their reports" on public.user_reports
  for select to authenticated using (reporter_id = auth.uid());

grant select, insert, delete on public.user_blocks to authenticated;
grant select, insert on public.user_reports to authenticated;

create or replace function public.get_blocked_users()
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  blocked_at timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  select b.blocked_id, coalesce(p.display_name, 'GoBuddy user'),
         null::text, b.created_at
  from public.user_blocks b
  left join public.user_accounts p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

revoke all on function public.get_blocked_users() from public;
grant execute on function public.get_blocked_users() to authenticated;

-- The request RPC remains the authoritative boundary for new interactions.
create or replace function public.users_are_blocked(p_first uuid, p_second uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.user_blocks
    where (blocker_id = p_first and blocked_id = p_second)
       or (blocker_id = p_second and blocked_id = p_first)
  );
$$;

revoke all on function public.users_are_blocked(uuid, uuid) from public;
grant execute on function public.users_are_blocked(uuid, uuid) to authenticated;

create or replace function public.reject_blocked_trip_interaction()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_owner_id uuid;
begin
  select owner_id into v_owner_id
  from public.matchmaking_trips
  where id = new.trip_id;
  if public.users_are_blocked(new.applicant_id, v_owner_id) then
    raise exception 'This interaction is unavailable';
  end if;
  return new;
end;
$$;

drop trigger if exists reject_blocked_join_request
  on public.matchmaking_join_requests;
create trigger reject_blocked_join_request
before insert or update on public.matchmaking_join_requests
for each row execute function public.reject_blocked_trip_interaction();

drop policy if exists "members read messages" on public.trip_messages;
drop policy if exists "members read unblocked messages" on public.trip_messages;
create policy "members read unblocked messages" on public.trip_messages
for select to authenticated using (
  public.is_trip_member(trip_id)
  and not public.users_are_blocked(auth.uid(), sender_id)
);
