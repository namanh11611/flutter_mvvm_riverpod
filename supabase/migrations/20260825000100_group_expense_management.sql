-- Group Expense Management: additive schema, atomic RPCs, RLS, and private receipts.
-- Shared tables (matchmaking_trips, trip_members, user_accounts) are intentionally untouched.

begin;

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.expense_categories (
  id integer primary key,
  name text not null unique,
  icon_name text not null
);

insert into public.expense_categories (id, name, icon_name) values
  (1, 'Hotel', 'hotel'), (2, 'Flight', 'flight'), (3, 'Food', 'food'),
  (4, 'Restaurant', 'restaurant'), (5, 'Transportation', 'transportation'),
  (6, 'Fuel', 'fuel'), (7, 'Parking', 'parking'), (8, 'Shopping', 'shopping'),
  (9, 'Entertainment', 'entertainment'), (10, 'Attraction', 'attraction'),
  (11, 'Others', 'others')
on conflict (id) do update set name = excluded.name, icon_name = excluded.icon_name;

create table if not exists public.trip_budgets (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  budget_name text not null,
  budget_amount numeric(18,2) not null check (budget_amount > 0),
  base_currency text not null check (base_currency in ('MYR','USD','SGD','JPY','THB','EUR')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (trip_id)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  paid_by_user_id uuid not null references auth.users(id),
  category_id integer not null references public.expense_categories(id),
  title text not null,
  original_amount numeric(18,2) not null check (original_amount > 0),
  currency_code text not null check (currency_code in ('MYR','USD','SGD','JPY','THB','EUR')),
  exchange_rate numeric(18,8) not null check (exchange_rate > 0),
  base_amount numeric(18,2) not null check (base_amount > 0),
  expense_date date not null,
  notes text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.expense_participants (
  expense_id uuid not null references public.expenses(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  share_amount numeric(18,2) not null check (share_amount >= 0),
  share_percentage numeric(7,4) check (share_percentage is null or share_percentage between 0 and 100),
  primary key (expense_id, user_id)
);

create table if not exists public.expense_receipts (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null unique references public.expenses(id) on delete cascade,
  object_path text not null,
  uploaded_at timestamptz not null default now()
);

create table if not exists public.settlements (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  payer_id uuid not null references auth.users(id),
  payee_id uuid not null references auth.users(id),
  amount numeric(18,2) not null check (amount > 0),
  payment_method text not null check (payment_method in ('Cash','Bank Transfer','Touch ''n Go','DuitNow','Credit Card','Other')),
  settlement_date date not null,
  status text not null default 'pending' check (status in ('pending','completed','rejected')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (payer_id <> payee_id)
);

create table if not exists public.settlement_receipts (
  id uuid primary key default gen_random_uuid(),
  settlement_id uuid not null unique references public.settlements(id) on delete cascade,
  object_path text not null,
  uploaded_at timestamptz not null default now()
);

create index if not exists expenses_trip_date_idx on public.expenses (trip_id, expense_date desc);
create index if not exists expenses_paid_by_idx on public.expenses (paid_by_user_id);
create index if not exists expenses_created_by_idx on public.expenses (created_by);
create index if not exists expenses_category_idx on public.expenses (category_id);
create index if not exists expense_participants_user_idx on public.expense_participants (user_id);
create index if not exists settlements_trip_status_idx on public.settlements (trip_id, status);
create index if not exists settlements_payer_idx on public.settlements (payer_id);
create index if not exists settlements_payee_idx on public.settlements (payee_id);

create or replace function public.group_expense_set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists trip_budgets_set_updated_at on public.trip_budgets;
create trigger trip_budgets_set_updated_at before update on public.trip_budgets
for each row execute function public.group_expense_set_updated_at();
drop trigger if exists expenses_set_updated_at on public.expenses;
create trigger expenses_set_updated_at before update on public.expenses
for each row execute function public.group_expense_set_updated_at();
drop trigger if exists settlements_set_updated_at on public.settlements;
create trigger settlements_set_updated_at before update on public.settlements
for each row execute function public.group_expense_set_updated_at();

create or replace function public.group_expense_protect_expense_identity() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.trip_id <> old.trip_id or new.created_by <> old.created_by then
    raise exception 'expense_identity_is_immutable' using errcode='22023';
  end if;
  return new;
end;
$$;
drop trigger if exists expenses_protect_identity on public.expenses;
create trigger expenses_protect_identity before update on public.expenses
for each row execute function public.group_expense_protect_expense_identity();

-- Membership/ownership helpers avoid recursive policy expressions and centralize authorization.
create or replace function public.group_expense_is_trip_member(p_trip_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = '' as $$
  select p_user_id is not null and exists (
    select 1 from public.trip_members tm where tm.trip_id = p_trip_id and tm.user_id = p_user_id
  );
$$;
create or replace function public.group_expense_is_trip_owner(p_trip_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = '' as $$
  select p_user_id is not null and exists (
    select 1 from public.matchmaking_trips mt where mt.id = p_trip_id and mt.owner_id = p_user_id
  );
$$;
revoke all on function public.group_expense_is_trip_member(uuid, uuid) from public;
revoke all on function public.group_expense_is_trip_owner(uuid, uuid) from public;
grant execute on function public.group_expense_is_trip_member(uuid, uuid), public.group_expense_is_trip_owner(uuid, uuid) to authenticated;

alter table public.expense_categories enable row level security;
alter table public.trip_budgets enable row level security;
alter table public.expenses enable row level security;
alter table public.expense_participants enable row level security;
alter table public.expense_receipts enable row level security;
alter table public.settlements enable row level security;
alter table public.settlement_receipts enable row level security;

drop policy if exists expense_categories_read on public.expense_categories;
create policy expense_categories_read on public.expense_categories for select to authenticated using (true);

drop policy if exists trip_budgets_member_read on public.trip_budgets;
create policy trip_budgets_member_read on public.trip_budgets for select to authenticated using (public.group_expense_is_trip_member(trip_id));
drop policy if exists trip_budgets_owner_insert on public.trip_budgets;
create policy trip_budgets_owner_insert on public.trip_budgets for insert to authenticated with check (public.group_expense_is_trip_owner(trip_id));
drop policy if exists trip_budgets_owner_update on public.trip_budgets;
create policy trip_budgets_owner_update on public.trip_budgets for update to authenticated using (public.group_expense_is_trip_owner(trip_id)) with check (public.group_expense_is_trip_owner(trip_id));
drop policy if exists trip_budgets_owner_delete on public.trip_budgets;
create policy trip_budgets_owner_delete on public.trip_budgets for delete to authenticated using (public.group_expense_is_trip_owner(trip_id));

drop policy if exists expenses_member_read on public.expenses;
create policy expenses_member_read on public.expenses for select to authenticated using (public.group_expense_is_trip_member(trip_id));
drop policy if exists expenses_member_insert on public.expenses;
create policy expenses_member_insert on public.expenses for insert to authenticated with check (
  created_by = auth.uid() and public.group_expense_is_trip_member(trip_id) and public.group_expense_is_trip_member(trip_id, paid_by_user_id)
);
drop policy if exists expenses_creator_owner_update on public.expenses;
create policy expenses_creator_owner_update on public.expenses for update to authenticated
using (created_by = auth.uid() or public.group_expense_is_trip_owner(trip_id))
with check ((created_by = auth.uid() or public.group_expense_is_trip_owner(trip_id)) and public.group_expense_is_trip_member(trip_id, paid_by_user_id));
drop policy if exists expenses_creator_owner_delete on public.expenses;
create policy expenses_creator_owner_delete on public.expenses for delete to authenticated using (created_by = auth.uid() or public.group_expense_is_trip_owner(trip_id));

drop policy if exists expense_participants_member_read on public.expense_participants;
create policy expense_participants_member_read on public.expense_participants for select to authenticated using (
  exists (select 1 from public.expenses e where e.id = expense_id and public.group_expense_is_trip_member(e.trip_id))
);
drop policy if exists expense_participants_author_write on public.expense_participants;
create policy expense_participants_author_write on public.expense_participants for all to authenticated
using (exists (select 1 from public.expenses e where e.id = expense_id and (e.created_by = auth.uid() or public.group_expense_is_trip_owner(e.trip_id))))
with check (exists (select 1 from public.expenses e where e.id = expense_id and (e.created_by = auth.uid() or public.group_expense_is_trip_owner(e.trip_id)) and public.group_expense_is_trip_member(e.trip_id, user_id)));

drop policy if exists expense_receipts_member_read on public.expense_receipts;
create policy expense_receipts_member_read on public.expense_receipts for select to authenticated using (
  exists (select 1 from public.expenses e where e.id = expense_id and public.group_expense_is_trip_member(e.trip_id))
);
drop policy if exists expense_receipts_author_write on public.expense_receipts;
create policy expense_receipts_author_write on public.expense_receipts for all to authenticated
using (exists (select 1 from public.expenses e where e.id = expense_id and (e.created_by = auth.uid() or public.group_expense_is_trip_owner(e.trip_id))))
with check (exists (select 1 from public.expenses e where e.id = expense_id and (e.created_by = auth.uid() or public.group_expense_is_trip_owner(e.trip_id))));

drop policy if exists settlements_member_read on public.settlements;
create policy settlements_member_read on public.settlements for select to authenticated using (public.group_expense_is_trip_member(trip_id));
drop policy if exists settlements_payer_insert on public.settlements;
create policy settlements_payer_insert on public.settlements for insert to authenticated with check (
  payer_id = auth.uid() and status = 'pending' and public.group_expense_is_trip_member(trip_id, payer_id) and public.group_expense_is_trip_member(trip_id, payee_id)
);
drop policy if exists settlements_payer_delete_pending on public.settlements;
create policy settlements_payer_delete_pending on public.settlements for delete to authenticated using (payer_id = auth.uid() and status = 'pending');

drop policy if exists settlement_receipts_member_read on public.settlement_receipts;
create policy settlement_receipts_member_read on public.settlement_receipts for select to authenticated using (
  exists (select 1 from public.settlements s where s.id = settlement_id and public.group_expense_is_trip_member(s.trip_id))
);
drop policy if exists settlement_receipts_payer_write_pending on public.settlement_receipts;
create policy settlement_receipts_payer_write_pending on public.settlement_receipts for all to authenticated
using (exists (select 1 from public.settlements s where s.id = settlement_id and s.payer_id = auth.uid() and s.status = 'pending'))
with check (exists (select 1 from public.settlements s where s.id = settlement_id and s.payer_id = auth.uid() and s.status = 'pending'));

-- Atomic expense write RPCs. JSON participants contain user_id/share_amount/share_percentage.
create or replace function public.group_expense_create_expense_with_participants(
  p_trip_id uuid, p_paid_by_user_id uuid, p_category_id integer, p_title text,
  p_original_amount numeric, p_currency_code text, p_exchange_rate numeric,
  p_base_amount numeric, p_expense_date date, p_notes text, p_participants jsonb
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare v_id uuid; v_total numeric; v_count integer;
begin
  if auth.uid() is null or not public.group_expense_is_trip_member(p_trip_id) or not public.group_expense_is_trip_member(p_trip_id, p_paid_by_user_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if jsonb_typeof(p_participants) <> 'array' or jsonb_array_length(p_participants) = 0 then raise exception 'participants_required' using errcode='22023'; end if;
  select coalesce(sum((x->>'share_amount')::numeric),0), count(*) into v_total,v_count from jsonb_array_elements(p_participants) x;
  if abs(v_total - p_base_amount) > 0.005 then raise exception 'shares_do_not_reconcile' using errcode='22023'; end if;
  if exists (select 1 from jsonb_array_elements(p_participants) x where not public.group_expense_is_trip_member(p_trip_id,(x->>'user_id')::uuid)) then raise exception 'participant_not_member' using errcode='42501'; end if;
  insert into public.expenses (trip_id,paid_by_user_id,category_id,title,original_amount,currency_code,exchange_rate,base_amount,expense_date,notes,created_by)
  values (p_trip_id,p_paid_by_user_id,p_category_id,p_title,p_original_amount,p_currency_code,p_exchange_rate,p_base_amount,p_expense_date,p_notes,auth.uid()) returning id into v_id;
  insert into public.expense_participants (expense_id,user_id,share_amount,share_percentage)
  select v_id,(x->>'user_id')::uuid,(x->>'share_amount')::numeric,nullif(x->>'share_percentage','')::numeric from jsonb_array_elements(p_participants) x;
  return v_id;
end $$;

create or replace function public.group_expense_update_expense_with_participants(
  p_expense_id uuid, p_trip_id uuid, p_paid_by_user_id uuid, p_category_id integer,
  p_title text, p_original_amount numeric, p_currency_code text, p_exchange_rate numeric,
  p_base_amount numeric, p_expense_date date, p_notes text, p_participants jsonb
) returns void language plpgsql security invoker set search_path = '' as $$
declare v_existing public.expenses; v_total numeric;
begin
  select * into v_existing from public.expenses where id=p_expense_id and trip_id=p_trip_id for update;
  if not found then raise exception 'expense_not_found' using errcode='P0002'; end if;
  if auth.uid() is null or (v_existing.created_by <> auth.uid() and not public.group_expense_is_trip_owner(p_trip_id)) then raise exception 'not_authorized' using errcode='42501'; end if;
  if not public.group_expense_is_trip_member(p_trip_id,p_paid_by_user_id) then raise exception 'payer_not_member' using errcode='42501'; end if;
  select coalesce(sum((x->>'share_amount')::numeric),0) into v_total from jsonb_array_elements(p_participants) x;
  if jsonb_array_length(p_participants)=0 or abs(v_total-p_base_amount)>0.005 then raise exception 'shares_do_not_reconcile' using errcode='22023'; end if;
  if exists (select 1 from jsonb_array_elements(p_participants) x where not public.group_expense_is_trip_member(p_trip_id,(x->>'user_id')::uuid)) then raise exception 'participant_not_member' using errcode='42501'; end if;
  update public.expenses set paid_by_user_id=p_paid_by_user_id,category_id=p_category_id,title=p_title,original_amount=p_original_amount,currency_code=p_currency_code,exchange_rate=p_exchange_rate,base_amount=p_base_amount,expense_date=p_expense_date,notes=p_notes where id=p_expense_id;
  delete from public.expense_participants where expense_id=p_expense_id;
  insert into public.expense_participants (expense_id,user_id,share_amount,share_percentage)
  select p_expense_id,(x->>'user_id')::uuid,(x->>'share_amount')::numeric,nullif(x->>'share_percentage','')::numeric from jsonb_array_elements(p_participants) x;
end $$;

create or replace function public.group_expense_transition_settlement(p_settlement_id uuid, p_status text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_settlement public.settlements;
begin
  if p_status not in ('completed','rejected') then raise exception 'invalid_transition' using errcode='22023'; end if;
  select * into v_settlement from public.settlements where id=p_settlement_id for update;
  if not found then raise exception 'settlement_not_found' using errcode='P0002'; end if;
  if v_settlement.status <> 'pending' or v_settlement.payee_id <> auth.uid() then raise exception 'not_authorized' using errcode='42501'; end if;
  update public.settlements set status=p_status where id=p_settlement_id;
end $$;

revoke all on function public.group_expense_create_expense_with_participants(uuid,uuid,integer,text,numeric,text,numeric,numeric,date,text,jsonb) from public;
revoke all on function public.group_expense_update_expense_with_participants(uuid,uuid,uuid,integer,text,numeric,text,numeric,numeric,date,text,jsonb) from public;
revoke all on function public.group_expense_transition_settlement(uuid,text) from public;
grant execute on function public.group_expense_create_expense_with_participants(uuid,uuid,integer,text,numeric,text,numeric,numeric,date,text,jsonb) to authenticated;
grant execute on function public.group_expense_update_expense_with_participants(uuid,uuid,uuid,integer,text,numeric,text,numeric,numeric,date,text,jsonb) to authenticated;
grant execute on function public.group_expense_transition_settlement(uuid,text) to authenticated;

insert into storage.buckets (id,name,public) values ('group-expense-receipts','group-expense-receipts',false)
on conflict (id) do update set public=false;

-- Storage authorization is anchored in DB receipt metadata, not merely parsed paths.
drop policy if exists group_expense_receipts_read on storage.objects;
create policy group_expense_receipts_read on storage.objects for select to authenticated using (
  bucket_id='group-expense-receipts' and (
    exists (select 1 from public.expense_receipts r join public.expenses e on e.id=r.expense_id where r.object_path=name and public.group_expense_is_trip_member(e.trip_id)) or
    exists (select 1 from public.settlement_receipts r join public.settlements s on s.id=r.settlement_id where r.object_path=name and public.group_expense_is_trip_member(s.trip_id))
  )
);
drop policy if exists group_expense_receipts_insert on storage.objects;
create policy group_expense_receipts_insert on storage.objects for insert to authenticated with check (
  bucket_id='group-expense-receipts' and (storage.foldername(name))[1]='trips'
  and (
    ((storage.foldername(name))[3]='expenses' and exists (
      select 1 from public.expenses e
      where e.id=((storage.foldername(name))[4])::uuid
        and e.trip_id=((storage.foldername(name))[2])::uuid
        and (e.created_by=auth.uid() or public.group_expense_is_trip_owner(e.trip_id))
    ))
    or
    ((storage.foldername(name))[3]='settlements' and exists (
      select 1 from public.settlements s
      where s.id=((storage.foldername(name))[4])::uuid
        and s.trip_id=((storage.foldername(name))[2])::uuid
        and s.payer_id=auth.uid() and s.status='pending'
    ))
  )
);
drop policy if exists group_expense_receipts_update on storage.objects;
create policy group_expense_receipts_update on storage.objects for update to authenticated using (
  bucket_id='group-expense-receipts' and (
    exists (select 1 from public.expense_receipts r join public.expenses e on e.id=r.expense_id where r.object_path=name and (e.created_by=auth.uid() or public.group_expense_is_trip_owner(e.trip_id))) or
    exists (select 1 from public.settlement_receipts r join public.settlements s on s.id=r.settlement_id where r.object_path=name and s.payer_id=auth.uid() and s.status='pending') or
    ((storage.foldername(name))[3]='expenses' and exists (
      select 1 from public.expenses e where e.id=((storage.foldername(name))[4])::uuid
      and e.trip_id=((storage.foldername(name))[2])::uuid and (e.created_by=auth.uid() or public.group_expense_is_trip_owner(e.trip_id))
    )) or
    ((storage.foldername(name))[3]='settlements' and exists (
      select 1 from public.settlements s where s.id=((storage.foldername(name))[4])::uuid
      and s.trip_id=((storage.foldername(name))[2])::uuid and s.payer_id=auth.uid() and s.status='pending'
    ))
  )
);
drop policy if exists group_expense_receipts_delete on storage.objects;
create policy group_expense_receipts_delete on storage.objects for delete to authenticated using (
  bucket_id='group-expense-receipts' and (
    exists (select 1 from public.expense_receipts r join public.expenses e on e.id=r.expense_id where r.object_path=name and (e.created_by=auth.uid() or public.group_expense_is_trip_owner(e.trip_id))) or
    exists (select 1 from public.settlement_receipts r join public.settlements s on s.id=r.settlement_id where r.object_path=name and s.payer_id=auth.uid() and s.status='pending')
  )
);

commit;
