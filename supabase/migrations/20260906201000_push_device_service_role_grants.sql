-- The push Edge Function uses the service-role client to look up recipient
-- devices and remove tokens rejected permanently by FCM.

grant select, delete on public.push_device_tokens to service_role;
