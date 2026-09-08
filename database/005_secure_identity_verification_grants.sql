-- Verification attempts and trusted statuses are written only by backend code.
grant select on table public.identity_verifications to authenticated;
revoke insert, update, delete on table public.identity_verifications
  from authenticated;

grant select, insert, update on table public.identity_verifications
  to service_role;
grant select, update on table public.user_accounts to service_role;
