import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CurrencyPair = ({String from, String to});

final currencyConversionRateProvider =
    FutureProvider.family<double, CurrencyPair>((ref, pair) async {
      if (pair.from == pair.to) return 1;
      final response = await Dio(
        BaseOptions(
          baseUrl: 'https://api.frankfurter.dev',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ).get<Map<String, dynamic>>('/v2/rate/${pair.from}/${pair.to}');
      final rate = response.data?['rate'];
      if (rate is! num || rate <= 0) throw StateError('Invalid exchange rate');
      return rate.toDouble();
    });
