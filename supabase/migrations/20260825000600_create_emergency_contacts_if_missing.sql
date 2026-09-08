-- Repair migration: the app expects this table, but it may be missing from a
-- project where the earlier emergency-contacts migration was not deployed.
create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 100),
  phone_number text not null check (phone_number ~ '^\+?[0-9]{7,15}$'),
  email text not null check (
    email = lower(email)
    and char_length(email) between 3 and 254
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, phone_number),
  unique (user_id, email)
);

create index if not exists emergency_contacts_user_created_idx
  on public.emergency_contacts(user_id, created_at);

alter table public.emergency_contacts enable row level security;

drop policy if exists "users read their emergency contacts"
  on public.emergency_contacts;
create policy "users read their emergency contacts"
  on public.emergency_contacts for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "users create their emergency contacts"
  on public.emergency_contacts;
create policy "users create their emergency contacts"
  on public.emergency_contacts for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "users update their emergency contacts"
  on public.emergency_contacts;
create policy "users update their emergency contacts"
  on public.emergency_contacts for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "users delete their emergency contacts"
  on public.emergency_contacts;
create policy "users delete their emergency contacts"
  on public.emergency_contacts for delete to authenticated
  using (user_id = auth.uid());

grant select, insert, update, delete
  on public.emergency_contacts to authenticated;
