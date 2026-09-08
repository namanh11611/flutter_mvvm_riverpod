-- BYPASSRLS does not grant table privileges. The moderation Edge Function uses
-- service_role, while several older application tables only grant authenticated.
grant select, update on public.user_reports to service_role;
grant select, update on public.user_accounts to service_role;
grant select, delete on public.user_gallery to service_role;
