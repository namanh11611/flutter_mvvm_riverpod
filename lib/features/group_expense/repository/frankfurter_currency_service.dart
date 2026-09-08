import 'package:dio/dio.dart';

import '../model/expense_constants.dart';
import 'currency_service.dart';

class ExchangeRateException implements Exception {
  const ExchangeRateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fetches current reference rates from Frankfurter's public v2 API.
///
/// Frankfurter aggregates daily reference rates; these are not live trading
/// prices. The selected quote is stored on the expense, so historical expenses
/// never recalculate merely because the reference rate later changes.
class FrankfurterCurrencyService implements CurrencyService {
  FrankfurterCurrencyService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.frankfurter.dev',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  @override
  Future<ExchangeRateQuote> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    _validate(from);
    _validate(to);
    if (from == to) {
      return ExchangeRateQuote(
        fromCurrency: from,
        toCurrency: to,
        rate: 1,
        source: 'Same currency',
        rateDate: DateTime.now().toUtc(),
      );
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v2/rate/$from/$to',
      );
      final data = response.data;
      final rate = data?['rate'];
      final base = data?['base'];
      final quote = data?['quote'];
      final date = data?['date'];
      if (rate is! num || !rate.toDouble().isFinite || rate <= 0 ||
          base != from || quote != to || date is! String) {
        throw const ExchangeRateException('Invalid exchange-rate response.');
      }
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate == null) {
        throw const ExchangeRateException('Invalid exchange-rate response.');
      }
      return ExchangeRateQuote(
        fromCurrency: from,
        toCurrency: to,
        rate: rate.toDouble(),
        source: 'Frankfurter',
        rateDate: parsedDate,
      );
    } on ExchangeRateException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 404 || status == 422) {
        throw const ExchangeRateException('Unsupported currency pair.');
      }
      throw const ExchangeRateException(
        'Unable to fetch the latest exchange rate. Please try again.',
      );
    } catch (_) {
      throw const ExchangeRateException(
        'Unable to fetch the latest exchange rate. Please try again.',
      );
    }
  }

  void _validate(String currency) {
    if (!ExpenseConstants.supportedCurrencies.contains(currency)) {
      throw const ExchangeRateException('Unsupported currency pair.');
    }
  }
}
