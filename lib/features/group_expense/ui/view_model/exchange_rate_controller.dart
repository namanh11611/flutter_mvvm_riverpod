import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../repository/currency_service.dart';
import '../../repository/group_expense_providers.dart';

part 'exchange_rate_controller.g.dart';

@riverpod
class ExchangeRateController extends _$ExchangeRateController {
  @override
  FutureOr<ExchangeRateQuote?> build({
    required String fromCurrency,
    required String toCurrency,
  }) => null;

  Future<void> fetch() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(currencyServiceProvider).getExchangeRate(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
          ),
    );
  }
}
