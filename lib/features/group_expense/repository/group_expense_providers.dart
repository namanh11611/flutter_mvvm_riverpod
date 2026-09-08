import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/remote/supabase_client.dart';
import 'budget_repository.dart';
import 'analytics_repository.dart';
import 'currency_service.dart';
import 'frankfurter_currency_service.dart';
import 'expense_repository.dart';
import 'receipt_file_service.dart';
import 'receipt_storage_service.dart';
import 'settlement_repository.dart';
import 'supabase_budget_repository.dart';
import 'supabase_analytics_repository.dart';
import 'supabase_expense_repository.dart';
import 'supabase_receipt_storage_service.dart';
import 'supabase_settlement_repository.dart';
import 'supabase_traveller_repository.dart';
import 'supabase_trip_repository.dart';
import 'traveller_repository.dart';
import 'trip_repository.dart';

/// Shared-auth boundary for Group Expense.
///
/// Tests may override this provider without coupling the feature to the
/// authentication module's temporary fake-login implementation.
final groupExpenseAuthChangesProvider = StreamProvider((ref) {
  return supabase.auth.onAuthStateChange;
});

final authenticatedUserIdProvider = Provider<String?>((ref) {
  // Re-evaluate the authenticated user whenever Supabase changes sessions.
  // Reading currentUser directly without this dependency leaves Group Expense
  // providers scoped to the account that first opened them.
  ref.watch(groupExpenseAuthChangesProvider);
  return supabase.auth.currentUser?.id;
});

final currencyServiceProvider =
    Provider<CurrencyService>((ref) => FrankfurterCurrencyService());

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return SupabaseReceiptStorageService(supabase);
});

final receiptFileServiceProvider = Provider<ReceiptFileService>((ref) {
  return SupabaseReceiptStorageService(supabase);
});

final travellerRepositoryProvider =
    FutureProvider<TravellerRepository>((ref) async {
  return SupabaseTravellerRepository(supabase);
});

final tripRepositoryProvider = FutureProvider<TripRepository>((ref) async {
  return SupabaseTripRepository(supabase);
});

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  return SupabaseBudgetRepository(supabase);
});

final analyticsRepositoryProvider =
    FutureProvider<AnalyticsRepository>((ref) async {
  return SupabaseAnalyticsRepository(supabase);
});

final expenseRepositoryProvider =
    FutureProvider<ExpenseRepository>((ref) async {
  return SupabaseExpenseRepository(
    supabase,
    ref.watch(receiptStorageServiceProvider),
  );
});

final settlementRepositoryProvider =
    FutureProvider<SettlementRepository>((ref) async {
  return SupabaseSettlementRepository(
    supabase,
    ref.watch(receiptStorageServiceProvider),
  );
});
