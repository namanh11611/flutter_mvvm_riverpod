import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';

import '../features/common/remote/api_client.dart';
import '../generated/locale_keys.g.dart';

class Utils {
  Utils._();

  static Future<bool> haveConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  static String getErrorMessage(Object? error) {
    if (error is TimeoutException) return error.message;
    if (error is NoInternetException) return error.message;
    if (error is RequestCancelledException) return error.message;
    if (error is BadRequestException) return error.message;
    if (error is UnauthorizedException) return error.message;
    if (error is ForbiddenException) return error.message;
    if (error is NotFoundException) return error.message;
    if (error is ServerException) return error.message;
    if (error is UnknownException) return error.message;
    return LocaleKeys.unexpectedErrorOccurred.tr();
  }

  static DateTime today() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }
}
