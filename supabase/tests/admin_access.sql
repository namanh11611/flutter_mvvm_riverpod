-- Run after the admin migration. All fixture changes are rolled back.
begin;
do $$ declare normal_id uuid; admin_id uuid; begin
  select user_id into admin_id from public.admin_users limit 1;
  select id into normal_id from auth.users where id not in (select user_id from public.admin_users) limit 1;
  if normal_id is null or admin_id is null then raise exception 'Requires one normal and one admin account'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', admin_id, 'role', 'authenticated')::text, true);
  if public.get_account_access() <> 'admin' then raise exception 'Admin role lookup failed'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', normal_id, 'role', 'authenticated', 'user_metadata', json_build_object('role', 'admin'))::text, true);
  if public.get_account_access() <> 'user' then raise exception 'User metadata elevated privileges'; end if;
  insert into public.account_bans(user_id, reason, created_by) values(normal_id, 'Transaction-only test', admin_id);
  if public.get_account_access() <> 'banned' or public.account_is_active() then raise exception 'Ban lookup failed'; end if;
  perform set_config('request.path', '/rpc/get_account_access', true);
  perform public.check_account_access();
  perform set_config('request.path', '/rpc/get_blocked_users', true);
  begin
    perform public.check_account_access();
    raise exception 'Banned RPC was allowed';
  exception when sqlstate 'PT403' then null;
  end;
end $$;
set local role authenticated;
do $$ begin
  begin
    insert into public.admin_users(user_id) values(auth.uid());
    raise exception 'Ordinary user can grant admin';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.account_bans where user_id = auth.uid();
    raise exception 'Ordinary user can unban themselves';
  exception when insufficient_privilege then null;
  end;
  if exists(select 1 from public.user_accounts) then raise exception 'Banned user can read profiles'; end if;
end $$;
reset role;
rollback;
