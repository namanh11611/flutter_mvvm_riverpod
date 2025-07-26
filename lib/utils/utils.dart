import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/languages.dart';
import '../features/common/remote/api_client.dart';

class Utils {
  Utils._();

  static Future<bool> haveConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  static Future<bool> havePhotoPermission() async {
    PermissionStatus status = await Permission.photos.status;
    if (status == PermissionStatus.granted) return true;

    final result = await Permission.photos.request();
    if (result == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
    return result == PermissionStatus.granted;
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
    return Languages.unexpectedErrorOccurred;
  }

  static DateTime today() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }
}
