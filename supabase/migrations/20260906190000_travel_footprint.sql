create table if not exists public.visited_countries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  country_name text not null check (char_length(trim(country_name)) between 1 and 80),
  country_code text not null check (country_code ~ '^[A-Z]{2}$'),
  visited_at timestamptz not null default now(),
  unique (user_id, country_name)
);

create table if not exists public.visited_cities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  country_id uuid not null references public.visited_countries(id) on delete cascade,
  city_name text not null check (char_length(trim(city_name)) between 1 and 100),
  visited_at timestamptz not null default now(),
  unique (country_id, city_name)
);

alter table public.visited_countries enable row level security;
alter table public.visited_cities enable row level security;
create policy "users manage own visited countries" on public.visited_countries
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage own visited cities" on public.visited_cities
  for all to authenticated using (user_id = auth.uid()) with check (
    user_id = auth.uid() and exists (
      select 1 from public.visited_countries c where c.id = country_id and c.user_id = auth.uid()
    )
  );
grant select, insert, update, delete on public.visited_countries, public.visited_cities to authenticated;
