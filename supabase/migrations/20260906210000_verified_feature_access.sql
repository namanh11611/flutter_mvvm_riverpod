-- Identity verification is an authorization boundary, not only a UI state.
create or replace function public.current_user_is_identity_verified()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_accounts
    where id = auth.uid() and verification_status = 'verified'
  );
$$;

revoke all on function public.current_user_is_identity_verified() from public;
grant execute on function public.current_user_is_identity_verified() to authenticated;

-- Covers writes made through both the REST API and security-definer RPCs.
create or replace function public.require_verified_identity_for_feature_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- auth.uid() is null for trusted database maintenance/cron operations.
  if auth.uid() is not null and not public.current_user_is_identity_verified() then
    raise exception 'identity_verification_required' using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.require_verified_identity_for_feature_write() from public;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'matchmaking_trips', 'matchmaking_saved_trips', 'matchmaking_join_requests',
    'matchmaking_trip_members', 'trip_members', 'trip_messages',
    'trip_activities', 'trip_activity_rsvps', 'trip_activity_proposals',
    'trip_timeline_days', 'trip_polls', 'trip_poll_options', 'trip_poll_votes',
    'trip_files', 'trip_calls', 'trip_call_signals', 'trip_call_participants',
    'trip_typing_status', 'trip_message_reads',
    'trip_budgets', 'expenses', 'expense_participants', 'expense_receipts',
    'settlements', 'settlement_receipts'
  ] loop
    if to_regclass('public.' || table_name) is not null then
      execute format(
        'drop trigger if exists require_verified_identity_write on public.%I',
        table_name
      );
      execute format(
        'create trigger require_verified_identity_write before insert or update or delete on public.%I for each row execute function public.require_verified_identity_for_feature_write()',
        table_name
      );
    end if;
  end loop;
end $$;

-- Read access to collaboration and expense data is also restricted. Discovery
-- trips remain readable so an unverified user can browse/swipe their cards.
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'matchmaking_saved_trips', 'matchmaking_join_requests',
    'matchmaking_trip_members', 'trip_members', 'trip_messages',
    'trip_activities', 'trip_activity_rsvps', 'trip_activity_proposals',
    'trip_timeline_days', 'trip_polls', 'trip_poll_options', 'trip_poll_votes',
    'trip_files', 'trip_calls', 'trip_call_signals', 'trip_call_participants',
    'trip_typing_status', 'trip_message_reads',
    'trip_budgets', 'expenses', 'expense_participants', 'expense_receipts',
    'settlements', 'settlement_receipts'
  ] loop
    if to_regclass('public.' || table_name) is not null then
      execute format(
        'drop policy if exists identity_verification_required on public.%I',
        table_name
      );
      execute format(
        'create policy identity_verification_required on public.%I as restrictive for select to authenticated using ((select public.current_user_is_identity_verified()))',
        table_name
      );
    end if;
  end loop;
end $$;
