-- Expose Group Expense tables to authenticated Data API clients.
-- RLS remains authoritative for every row; anonymous clients receive nothing.

begin;

revoke all on table
  public.expense_categories,
  public.trip_budgets,
  public.expenses,
  public.expense_participants,
  public.expense_receipts,
  public.settlements,
  public.settlement_receipts
from anon;

grant select on table public.expense_categories to authenticated;

grant select, insert, update, delete on table
  public.trip_budgets,
  public.expenses,
  public.expense_participants,
  public.expense_receipts,
  public.settlements,
  public.settlement_receipts
to authenticated;

commit;
