import 'package:easy_localization/easy_localization.dart';

extension DateTimeExtension on DateTime {
  String toEEE() {
    return DateFormat('EEE').format(this);
  }

  String toEEEddMMYYYYHHmm() {
    return DateFormat('EEE, dd/MM/yyyy, HH:mm').format(this);
  }

  String toEEEddMMYYYY() {
    return DateFormat('EEE, dd/MM/yyyy').format(this);
  }

  String toddMMYYYY() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
