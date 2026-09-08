class ExchangeRateQuote {
  const ExchangeRateQuote({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.source,
    this.rateDate,
  });

  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final String source;
  final DateTime? rateDate;
}

abstract interface class CurrencyService {
  Future<ExchangeRateQuote> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  });
}
