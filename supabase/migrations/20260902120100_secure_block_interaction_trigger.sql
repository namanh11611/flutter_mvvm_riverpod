-- Trigger functions are invoked by PostgreSQL and must not be callable as RPCs.
revoke all on function public.reject_blocked_trip_interaction() from public;
