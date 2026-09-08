-- Rename the account profile table without recreating it, preserving its data,
-- constraints, RLS policies, grants, indexes, and foreign-key relationships.
do $$
begin
  if to_regclass('public.matchmaking_profiles') is not null
     and to_regclass('public.user_accounts') is null then
    alter table public.matchmaking_profiles rename to user_accounts;
  elsif to_regclass('public.matchmaking_profiles') is not null
        and to_regclass('public.user_accounts') is not null then
    raise exception
      'Cannot rename matchmaking_profiles: user_accounts already exists';
  elsif to_regclass('public.user_accounts') is null then
    raise exception
      'Cannot rename matchmaking_profiles: source table does not exist';
  end if;
end;
$$;

-- Function bodies can store relation names as SQL text. Recreate every public
-- function that still contains the old name so triggers and RPCs keep working.
do $$
declare
  function_record record;
begin
  for function_record in
    select p.oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and pg_get_functiondef(p.oid) like '%matchmaking_profiles%'
  loop
    execute replace(
      pg_get_functiondef(function_record.oid),
      'matchmaking_profiles',
      'user_accounts'
    );
  end loop;
end;
$$;

notify pgrst, 'reload schema';
