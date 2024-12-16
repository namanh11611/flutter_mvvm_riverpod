import 'package:easy_localization/easy_localization.dart';

extension DateTimeExtension on DateTime {
  String toEEEddMMYYYYHHmm() {
    return DateFormat('EEE, dd/MM/yyyy, HH:mm').format(this);
  }

  String toddMMYYYY() {
    return DateFormat('dd/MM/yyyy').format(this);
  }
}
