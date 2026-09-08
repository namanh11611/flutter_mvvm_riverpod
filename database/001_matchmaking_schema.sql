-- GoBuddy matchmaking schema.
-- Run once in the Supabase SQL Editor before 002_matchmaking_rls.sql.

create extension if not exists pgcrypto;

create type public.trip_status as enum ('active', 'closed', 'draft');
create type public.join_request_status as enum (
  'pending', 'held', 'accepted', 'declined', 'cancelled'
);

create table public.matchmaking_trips (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  destination text not null,
  start_date date not null,
  end_date date not null,
  budget numeric(12, 2) not null,
  vacancies integer not null,
  preferred_gender text not null default 'Any',
  minimum_age integer not null default 18,
  maximum_age integer not null default 80,
  description text not null,
  cover_image_url text,
  status public.trip_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_trip_dates check (end_date >= start_date),
  constraint positive_budget check (budget >= 0),
  constraint positive_vacancies check (vacancies > 0),
  constraint valid_minimum_age check (minimum_age >= 18),
  constraint valid_age_range check (maximum_age >= minimum_age),
  constraint valid_preferred_gender check (
    preferred_gender in ('Any', 'Female', 'Male')
  )
);

create table public.matchmaking_trip_styles (
  trip_id uuid not null
    references public.matchmaking_trips(id) on delete cascade,
  style text not null,
  primary key (trip_id, style)
);

create table public.matchmaking_join_requests (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null
    references public.matchmaking_trips(id) on delete cascade,
  applicant_id uuid not null references auth.users(id) on delete cascade,
  message text not null,
  status public.join_request_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (trip_id, applicant_id),
  constraint valid_request_message check (
    char_length(message) between 1 and 500
  )
);

create table public.matchmaking_trip_members (
  trip_id uuid not null
    references public.matchmaking_trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (trip_id, user_id),
  constraint valid_member_role check (role in ('owner', 'member'))
);

create table public.matchmaking_saved_trips (
  user_id uuid not null references auth.users(id) on delete cascade,
  trip_id uuid not null
    references public.matchmaking_trips(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, trip_id)
);

create index matchmaking_trips_owner_idx
  on public.matchmaking_trips(owner_id);
create index matchmaking_trips_discovery_idx
  on public.matchmaking_trips(status, start_date);
create index matchmaking_requests_trip_idx
  on public.matchmaking_join_requests(trip_id);
create index matchmaking_requests_applicant_idx
  on public.matchmaking_join_requests(applicant_id);
create index matchmaking_members_user_idx
  on public.matchmaking_trip_members(user_id);

