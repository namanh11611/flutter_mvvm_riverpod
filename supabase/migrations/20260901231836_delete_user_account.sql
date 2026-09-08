-- Service-role-only account deletion. The Edge Function authenticates the
-- caller and passes only that caller's user id to this function.
create or replace function public.delete_user_account(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids uuid[] := array[p_user_id];
  v_table record;
begin
  if p_user_id is null then
    raise exception 'A user id is required';
  end if;

  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'User account not found';
  end if;

  delete from public.matchmaking_trips where owner_id = p_user_id;

  for v_table in
    select
      namespace.nspname as schema_name,
      relation.relname as table_name,
      string_agg(
        format('%I = any($1)', attribute.attname),
        ' or ' order by attribute.attname
      ) as predicate
    from pg_catalog.pg_constraint constraint_record
    join pg_catalog.pg_class relation
      on relation.oid = constraint_record.conrelid
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    join unnest(constraint_record.conkey) with ordinality key_column(attnum, ord)
      on true
    join pg_catalog.pg_attribute attribute
      on attribute.attrelid = constraint_record.conrelid
     and attribute.attnum = key_column.attnum
    where constraint_record.contype = 'f'
      and constraint_record.confrelid = 'auth.users'::regclass
      and namespace.nspname = 'public'
      and relation.relname not in (
        'matchmaking_trips',
        'matchmaking_notifications'
      )
    group by namespace.nspname, relation.relname
    order by relation.relname
  loop
    execute format(
      'delete from %I.%I where %s',
      v_table.schema_name,
      v_table.table_name,
      v_table.predicate
    ) using v_ids;
  end loop;

  delete from public.matchmaking_notifications where user_id = p_user_id;
  delete from auth.users where id = p_user_id;
end;
$$;

revoke all on function public.delete_user_account(uuid) from public;
revoke all on function public.delete_user_account(uuid) from anon;
revoke all on function public.delete_user_account(uuid) from authenticated;
grant execute on function public.delete_user_account(uuid) to service_role;;
