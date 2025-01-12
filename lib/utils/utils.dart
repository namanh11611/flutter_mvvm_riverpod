import 'package:connectivity_plus/connectivity_plus.dart';

class Utils {
  Utils._();

  static Future<bool> haveConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  static DateTime today() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }
}
