import 'package:intl/intl.dart';

class ExpenseDateUtils {
  ExpenseDateUtils._();

  static String formatDate(DateTime date) =>
      DateFormat('d MMM yyyy').format(date);

  static String formatRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)}–${DateFormat('d, yyyy').format(end)}';
    }
    return '${DateFormat('MMM d').format(start)}–${DateFormat('MMM d, yyyy').format(end)}';
  }
}
