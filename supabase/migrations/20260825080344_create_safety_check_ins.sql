create table if not exists public.safety_check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  -- Kept as text because existing trip sources use more than one identifier type.
  trip_id text null,
  scheduled_at timestamptz not null default now(),
  response_deadline timestamptz not null default (now() + interval '15 minutes'),
  responded_at timestamptz null,
  status text not null default 'pending'
    check (status in ('pending', 'safe', 'needsHelp', 'missed')),
  last_latitude double precision null,
  last_longitude double precision null,
  contacts_alerted_at timestamptz null,
  created_at timestamptz not null default now()
);

create index if not exists safety_check_ins_pending_idx
  on public.safety_check_ins(response_deadline)
  where status = 'pending';

alter table public.safety_check_ins enable row level security;

drop policy if exists "Users read own safety check-ins"
  on public.safety_check_ins;
create policy "Users read own safety check-ins"
  on public.safety_check_ins for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users create own safety check-ins"
  on public.safety_check_ins;
create policy "Users create own safety check-ins"
  on public.safety_check_ins for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users respond to own safety check-ins"
  on public.safety_check_ins;
create policy "Users respond to own safety check-ins"
  on public.safety_check_ins for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update on public.safety_check_ins to authenticated;

comment on column public.safety_check_ins.contacts_alerted_at is
  'Set by the trusted backend after a pending check-in passes its deadline and emergency-contact alerts are sent.';;
