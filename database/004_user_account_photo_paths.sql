-- Keep user-account media as storage object paths, not environment-specific URLs.

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_accounts'
      and column_name = 'profile_photo_url'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_accounts'
      and column_name = 'profile_photo_path'
  ) then
    alter table public.user_accounts
      rename column profile_photo_url to profile_photo_path;
  end if;
end
$$;

alter table public.user_accounts
  add column if not exists nationality text,
  add column if not exists background_photo_path text;
