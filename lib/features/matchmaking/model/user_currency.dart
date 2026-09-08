import 'package:intl/intl.dart';

class UserCurrency {
  const UserCurrency(this.code, this.symbol);

  final String code;
  final String symbol;

  static const myr = UserCurrency('MYR', 'RM');

  String format(num amount) =>
      '$symbol ${NumberFormat.decimalPattern().format(amount)}';

  factory UserCurrency.fromNationality(String? nationality) {
    final value = nationality?.trim().toLowerCase() ?? '';
    for (final entry in _nationalityCurrencies.entries) {
      if (value == entry.key || value.contains(entry.key)) return entry.value;
    }
    return myr;
  }
}

const _nationalityCurrencies = <String, UserCurrency>{
  'malaysia': UserCurrency.myr,
  'malaysian': UserCurrency.myr,
  'singapore': UserCurrency('SGD', r'S$'),
  'singaporean': UserCurrency('SGD', r'S$'),
  'indonesia': UserCurrency('IDR', 'Rp'),
  'indonesian': UserCurrency('IDR', 'Rp'),
  'thailand': UserCurrency('THB', '฿'),
  'thai': UserCurrency('THB', '฿'),
  'vietnam': UserCurrency('VND', '₫'),
  'vietnamese': UserCurrency('VND', '₫'),
  'philippines': UserCurrency('PHP', '₱'),
  'filipino': UserCurrency('PHP', '₱'),
  'china': UserCurrency('CNY', '¥'),
  'chinese': UserCurrency('CNY', '¥'),
  'japan': UserCurrency('JPY', '¥'),
  'japanese': UserCurrency('JPY', '¥'),
  'south korea': UserCurrency('KRW', '₩'),
  'korean': UserCurrency('KRW', '₩'),
  'india': UserCurrency('INR', '₹'),
  'indian': UserCurrency('INR', '₹'),
  'australia': UserCurrency('AUD', r'A$'),
  'australian': UserCurrency('AUD', r'A$'),
  'new zealand': UserCurrency('NZD', r'NZ$'),
  'canada': UserCurrency('CAD', r'C$'),
  'canadian': UserCurrency('CAD', r'C$'),
  'united states': UserCurrency('USD', r'$'),
  'american': UserCurrency('USD', r'$'),
  'united kingdom': UserCurrency('GBP', '£'),
  'uk': UserCurrency('GBP', '£'),
  'british': UserCurrency('GBP', '£'),
  'english': UserCurrency('GBP', '£'),
  'peru': UserCurrency('PEN', r'S/'),
  'peruvian': UserCurrency('PEN', r'S/'),
  'brazil': UserCurrency('BRL', r'R$'),
  'brazilian': UserCurrency('BRL', r'R$'),
  'mexico': UserCurrency('MXN', r'MX$'),
  'mexican': UserCurrency('MXN', r'MX$'),
  'switzerland': UserCurrency('CHF', 'CHF'),
  'swiss': UserCurrency('CHF', 'CHF'),
  'turkey': UserCurrency('TRY', '₺'),
  'turkish': UserCurrency('TRY', '₺'),
  'south africa': UserCurrency('ZAR', 'R'),
  'nigeria': UserCurrency('NGN', '₦'),
  'pakistan': UserCurrency('PKR', 'Rs'),
  'bangladesh': UserCurrency('BDT', '৳'),
  'sri lanka': UserCurrency('LKR', 'Rs'),
  'nepal': UserCurrency('NPR', 'Rs'),
  'united arab emirates': UserCurrency('AED', 'AED'),
  'saudi arabia': UserCurrency('SAR', 'SAR'),
  'france': UserCurrency('EUR', '€'),
  'french': UserCurrency('EUR', '€'),
  'germany': UserCurrency('EUR', '€'),
  'german': UserCurrency('EUR', '€'),
  'italy': UserCurrency('EUR', '€'),
  'italian': UserCurrency('EUR', '€'),
  'spain': UserCurrency('EUR', '€'),
  'spanish': UserCurrency('EUR', '€'),
  'netherlands': UserCurrency('EUR', '€'),
  'dutch': UserCurrency('EUR', '€'),
  'portugal': UserCurrency('EUR', '€'),
  'portuguese': UserCurrency('EUR', '€'),
  'ireland': UserCurrency('EUR', '€'),
  'irish': UserCurrency('EUR', '€'),
  'austria': UserCurrency('EUR', '€'),
  'austrian': UserCurrency('EUR', '€'),
  'belgium': UserCurrency('EUR', '€'),
  'belgian': UserCurrency('EUR', '€'),
  'finland': UserCurrency('EUR', '€'),
  'finnish': UserCurrency('EUR', '€'),
  'greece': UserCurrency('EUR', '€'),
  'greek': UserCurrency('EUR', '€'),
};
