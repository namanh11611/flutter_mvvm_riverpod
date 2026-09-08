-- Restore the private Group Expense receipt upload policy after deployed
-- storage policy drift. Authorization remains trip and parent scoped.

begin;

drop policy if exists group_expense_receipts_insert on storage.objects;
create policy group_expense_receipts_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'group-expense-receipts'
  and (storage.foldername(name))[1] = 'trips'
  and public.group_expense_is_trip_member(
    ((storage.foldername(name))[2])::uuid
  )
  and (
    (
      (storage.foldername(name))[3] = 'expenses'
      and exists (
        select 1
        from public.expenses e
        where e.id = ((storage.foldername(name))[4])::uuid
          and e.trip_id = ((storage.foldername(name))[2])::uuid
          and (
            e.created_by = auth.uid()
            or public.group_expense_is_trip_owner(e.trip_id)
          )
      )
    )
    or
    (
      (storage.foldername(name))[3] = 'settlements'
      and exists (
        select 1
        from public.settlements s
        where s.id = ((storage.foldername(name))[4])::uuid
          and s.trip_id = ((storage.foldername(name))[2])::uuid
          and s.payer_id = auth.uid()
          and s.status = 'pending'
      )
    )
  )
);

commit;
