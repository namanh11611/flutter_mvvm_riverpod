import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/money_utils.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/currency_service.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/frankfurter_currency_service.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/exchange_rate_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

FrankfurterCurrencyService _service(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.frankfurter.dev'));
  dio.httpClientAdapter = adapter;
  return FrankfurterCurrencyService(dio: dio);
}

class _CompletingService implements CurrencyService {
  final completer = Completer<ExchangeRateQuote>();
  @override
  Future<ExchangeRateQuote> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) => completer.future;
}

void main() {
  test('parses USD to MYR v2 pair response', () async {
    final adapter = _Adapter((options) {
      expect(options.path, '/v2/rate/USD/MYR');
      return _json({'date': '2026-09-01', 'base': 'USD', 'quote': 'MYR', 'rate': 4.22123456});
    });
    final quote = await _service(adapter).getExchangeRate(fromCurrency: 'USD', toCurrency: 'MYR');
    expect(quote.rate, 4.22123456);
    expect(quote.source, 'Frankfurter');
    expect(quote.rateDate, DateTime(2026, 9, 1));
  });

  test('parses MYR to USD response without reversing it', () async {
    final adapter = _Adapter((_) => _json({'date': '2026-09-01', 'base': 'MYR', 'quote': 'USD', 'rate': 0.2369}));
    expect((await _service(adapter).getExchangeRate(fromCurrency: 'MYR', toCurrency: 'USD')).rate, 0.2369);
  });

  test('same currency returns one without an API call', () async {
    final adapter = _Adapter((_) => throw StateError('must not call'));
    final quote = await _service(adapter).getExchangeRate(fromCurrency: 'MYR', toCurrency: 'MYR');
    expect(quote.rate, 1);
    expect(adapter.calls, 0);
  });

  test('maps HTTP failure to a useful error', () async {
    final adapter = _Adapter((_) => _json({'message': 'failure'}, status: 500));
    expect(() => _service(adapter).getExchangeRate(fromCurrency: 'USD', toCurrency: 'MYR'), throwsA(isA<ExchangeRateException>()));
  });

  test('rejects malformed response', () async {
    final adapter = _Adapter((_) => _json({'date': 'bad', 'base': 'USD', 'quote': 'MYR', 'rate': 'oops'}));
    expect(() => _service(adapter).getExchangeRate(fromCurrency: 'USD', toCurrency: 'MYR'), throwsA(isA<ExchangeRateException>()));
  });

  test('rejects unsupported pair before making a request', () async {
    final adapter = _Adapter((_) => throw StateError('must not call'));
    expect(() => _service(adapter).getExchangeRate(fromCurrency: 'ABC', toCurrency: 'MYR'), throwsA(isA<ExchangeRateException>()));
    expect(adapter.calls, 0);
  });

  test('base amount uses cent-safe rounding without rounding rate', () {
    const rate = 4.22123456;
    expect(MoneyUtils.roundMoney(20 * rate), 84.42);
  });

  test('controller exposes loading then fetched quote', () async {
    final service = _CompletingService();
    final container = ProviderContainer(overrides: [
      currencyServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    final provider = exchangeRateControllerProvider(fromCurrency: 'USD', toCurrency: 'MYR');
    await container.read(provider.future);
    final future = container.read(provider.notifier).fetch();
    expect(container.read(provider).isLoading, isTrue);
    service.completer.complete(const ExchangeRateQuote(fromCurrency: 'USD', toCurrency: 'MYR', rate: 4.2, source: 'test'));
    await future;
    expect(container.read(provider).value?.rate, 4.2);
  });

  test('controller exposes service errors', () async {
    final container = ProviderContainer(overrides: [
      currencyServiceProvider.overrideWithValue(_FailingService()),
    ]);
    addTearDown(container.dispose);
    final provider = exchangeRateControllerProvider(fromCurrency: 'USD', toCurrency: 'MYR');
    await container.read(provider.future);
    await container.read(provider.notifier).fetch();
    expect(container.read(provider).hasError, isTrue);
  });
}

class _FailingService implements CurrencyService {
  @override
  Future<ExchangeRateQuote> getExchangeRate({required String fromCurrency, required String toCurrency}) {
    throw const ExchangeRateException('offline');
  }
}
