-- Enforce admin-owned itinerary publishing and give members a separate,
-- reviewable activity proposal workflow.

create table if not exists public.trip_activity_proposals (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  proposed_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  location text,
  start_time timestamptz not null,
  status text not null default 'pending_approval'
    check (status in ('pending_approval', 'accepted', 'rejected')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists trip_activity_proposals_trip_status_idx
  on public.trip_activity_proposals(trip_id, status, created_at desc);

alter table public.trip_activity_proposals enable row level security;

drop policy if exists "members read activity proposals"
  on public.trip_activity_proposals;
create policy "members read activity proposals"
  on public.trip_activity_proposals for select to authenticated using (
    public.is_trip_member(trip_id)
    and (public.is_trip_admin(trip_id) or proposed_by = auth.uid())
  );

drop policy if exists "members submit activity proposals"
  on public.trip_activity_proposals;
create policy "members submit activity proposals"
  on public.trip_activity_proposals for insert to authenticated with check (
    proposed_by = auth.uid()
    and public.is_trip_member(trip_id)
    and not public.is_trip_admin(trip_id)
    and status = 'pending_approval'
  );

drop policy if exists "admins review activity proposals"
  on public.trip_activity_proposals;
create policy "admins review activity proposals"
  on public.trip_activity_proposals for update to authenticated
  using (public.is_trip_admin(trip_id))
  with check (public.is_trip_admin(trip_id));

-- Official timeline activities are managed only by the creator/admin role.
drop policy if exists "members add activities" on public.trip_activities;
drop policy if exists "admins add activities" on public.trip_activities;
create policy "admins add activities"
  on public.trip_activities for insert to authenticated
  with check (public.is_trip_admin(trip_id));

drop policy if exists "members edit unlocked activities" on public.trip_activities;
drop policy if exists "admins edit activities" on public.trip_activities;
create policy "admins edit activities"
  on public.trip_activities for update to authenticated
  using (public.is_trip_admin(trip_id))
  with check (public.is_trip_admin(trip_id));

drop policy if exists "members delete unlocked activities" on public.trip_activities;
drop policy if exists "admins delete activities" on public.trip_activities;
create policy "admins delete activities"
  on public.trip_activities for delete to authenticated
  using (public.is_trip_admin(trip_id));

drop policy if exists "members add timeline days" on public.trip_timeline_days;
drop policy if exists "admins add timeline days" on public.trip_timeline_days;
create policy "admins add timeline days"
  on public.trip_timeline_days for insert to authenticated
  with check (created_by = auth.uid() and public.is_trip_admin(trip_id));

create or replace function public.delete_trip_timeline_day(
  p_trip_id uuid,
  p_day_date date,
  p_day_start timestamptz,
  p_day_end timestamptz
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted_activities integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_trip_admin(p_trip_id) then
    raise exception 'Only a trip admin can delete itinerary days';
  end if;
  if p_day_end <= p_day_start
      or p_day_end - p_day_start < interval '20 hours'
      or p_day_end - p_day_start > interval '28 hours' then
    raise exception 'Invalid itinerary day range';
  end if;
  if not exists (
    select 1 from public.trip_timeline_days
    where trip_id = p_trip_id and day_date = p_day_date
  ) and not exists (
    select 1 from public.trip_activities
    where trip_id = p_trip_id
      and start_time >= p_day_start
      and start_time < p_day_end
  ) then
    raise exception 'Timeline day not found';
  end if;

  delete from public.trip_activities
  where trip_id = p_trip_id
    and start_time >= p_day_start
    and start_time < p_day_end;
  get diagnostics v_deleted_activities = row_count;

  delete from public.trip_timeline_days
  where trip_id = p_trip_id and day_date = p_day_date;
  return v_deleted_activities;
end;
$$;

create or replace function public.review_trip_activity_proposal(
  p_proposal_id uuid,
  p_decision text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proposal public.trip_activity_proposals%rowtype;
  v_activity_id uuid;
begin
  if p_decision not in ('accepted', 'rejected') then
    raise exception 'Decision must be accepted or rejected';
  end if;

  select * into v_proposal
  from public.trip_activity_proposals
  where id = p_proposal_id
  for update;

  if v_proposal.id is null then
    raise exception 'Activity proposal not found';
  end if;
  if not public.is_trip_admin(v_proposal.trip_id) then
    raise exception 'Only a trip admin can review activity proposals';
  end if;
  if v_proposal.status <> 'pending_approval' then
    raise exception 'This activity proposal has already been reviewed';
  end if;

  if p_decision = 'accepted' then
    insert into public.trip_activities (trip_id, title, location, start_time)
    values (
      v_proposal.trip_id,
      v_proposal.title,
      v_proposal.location,
      v_proposal.start_time
    )
    returning id into v_activity_id;
  end if;

  update public.trip_activity_proposals
  set status = p_decision,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_proposal_id;

  return v_activity_id;
end;
$$;

alter table public.trip_activity_events
  drop constraint if exists trip_activity_events_event_type_check;
alter table public.trip_activity_events
  add constraint trip_activity_events_event_type_check check (
    event_type in (
      'activity_created', 'activity_edited', 'activity_pinned',
      'activity_removed', 'activity_shared', 'activity_proposal_submitted',
      'activity_proposal_accepted', 'activity_proposal_rejected',
      'vote_cast', 'comment_added', 'member_muted', 'member_unmuted',
      'member_removed', 'admin_assigned', 'admin_removed', 'file_shared',
      'file_deleted', 'call_started', 'call_joined', 'call_ended',
      'rsvp_updated'
    )
  );

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'trip_activity_proposals'
  ) then
    alter publication supabase_realtime
      add table public.trip_activity_proposals;
  end if;
end;
$$;

grant select, insert, update on public.trip_activity_proposals to authenticated;
revoke all on function public.review_trip_activity_proposal(uuid, text)
  from public;
grant execute on function public.review_trip_activity_proposal(uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
