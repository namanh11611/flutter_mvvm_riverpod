-- A user must still be able to access their own share after deactivating it.
-- Without this policy, setting is_active to false makes the updated row fail
-- the active-only trip-member SELECT policy used by PostgREST updates.
drop policy if exists "users read their own live location shares"
  on public.live_location_shares;
create policy "users read their own live location shares"
on public.live_location_shares for select to authenticated
using (user_id = auth.uid());
