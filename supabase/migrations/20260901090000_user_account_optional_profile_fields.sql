alter table public.user_accounts
  add column if not exists nationality text,
  add column if not exists background_photo_path text;

notify pgrst, 'reload schema';
