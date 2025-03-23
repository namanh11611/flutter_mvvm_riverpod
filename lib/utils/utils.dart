import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

  static DateTime today() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }
}
