alter table public.user_accounts
  add column if not exists onboarding_completed boolean not null default false;

-- Profiles that existed before onboarding was introduced should keep their
-- current app experience. New profiles receive the column default (false).
update public.user_accounts
set onboarding_completed = true;;
