-- Stop a share through a deliberately narrow security-definer function. This
-- avoids the inactive row being rejected by the active-only SELECT policy.
create or replace function public.stop_live_location_share(p_share_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.live_location_shares
  set is_active = false
  where id = p_share_id
    and user_id = auth.uid();

  if not found then
    raise exception 'Live location share not found or not owned by the current user';
  end if;
end;
$$;

revoke all on function public.stop_live_location_share(uuid) from public;
grant execute on function public.stop_live_location_share(uuid) to authenticated;

