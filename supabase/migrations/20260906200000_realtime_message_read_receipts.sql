-- A receipt row has no trip_id, so clients cannot subscribe to it with their
-- trip filter. Touch the parent message whenever a receipt changes; this emits
-- a trip_messages realtime UPDATE containing trip_id and makes sender-side
-- "Seen by" counters refresh reliably.

alter table public.trip_messages
  add column if not exists receipt_version bigint not null default 0;

create or replace function public.touch_trip_message_receipt_version()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trip_messages
  set receipt_version = receipt_version + 1
  where id = new.message_id;
  return new;
end;
$$;

revoke all on function public.touch_trip_message_receipt_version() from public;

drop trigger if exists on_trip_message_receipt_changed
  on public.trip_message_reads;
create trigger on_trip_message_receipt_changed
after insert or update of read_at on public.trip_message_reads
for each row execute function public.touch_trip_message_receipt_version();

-- Align existing messages too, and emit one parent-message update so clients
-- that are currently open replace stale zero counts immediately.
update public.trip_messages as message
set receipt_version = receipt.count
from (
  select message_id, count(*)::bigint as count
  from public.trip_message_reads
  group by message_id
) as receipt
where message.id = receipt.message_id
  and message.receipt_version <> receipt.count;
