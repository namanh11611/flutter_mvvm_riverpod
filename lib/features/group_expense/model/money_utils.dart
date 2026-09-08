import 'package:intl/intl.dart';

class MoneyUtils {
  MoneyUtils._();

  static int toCents(double amount) => (amount * 100).round();
  static double fromCents(int cents) => cents / 100;
  static double roundMoney(double amount) => fromCents(toCents(amount));
  static bool moneyEquals(double first, double second) =>
      toCents(first) == toCents(second);

  static String formatCurrency(double amount, {String currency = 'MYR'}) {
    final symbol = currency == 'MYR' ? 'RM' : currency;
    return '$symbol ${NumberFormat('#,##0.00').format(roundMoney(amount))}';
  }
}
