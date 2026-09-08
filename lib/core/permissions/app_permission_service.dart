import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Coordinates permissions which are needed by more than one feature.
class AppPermissionService {
  const AppPermissionService();

  /// Requests the permissions GoBuddy commonly needs up front. Feature entry
  /// points still check their own permissions in case these are denied or
  /// later revoked.
  Future<void> requestStartupPermissions() async {
    if (kIsWeb) return;
    for (final permission in <Permission>[
      Permission.locationWhenInUse,
      Permission.microphone,
    ]) {
      if (!await permission.isGranted) await permission.request();
    }
  }

  /// Requests camera access at the point where the user chooses to take a
  /// profile photo instead of prompting unexpectedly during app startup.
  Future<void> requireCameraPermission() async {
    if (kIsWeb) return;

    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const AppPermissionException(
        'Camera permission is required to take a photo. Allow it in your '
        'device settings, then try again.',
      );
    }
  }

  /// Returns only after every permission required by the call is granted.
  Future<void> requireCallPermissions({required bool withVideo}) async {
    if (kIsWeb) return;

    final permissions = <Permission>[
      Permission.microphone,
      if (withVideo) Permission.camera,
    ];
    final denied = <String>[];

    for (final permission in permissions) {
      var status = await permission.status;
      if (!status.isGranted) status = await permission.request();
      if (!status.isGranted) {
        denied.add(permission == Permission.camera ? 'camera' : 'microphone');
      }
    }

    if (denied.isNotEmpty) {
      throw AppPermissionException(
        '${_capitalise(denied.join(' and '))} permission is required to '
        '${withVideo ? 'join a video call' : 'join a voice call'}. '
        'Allow it in your device settings, then try again.',
      );
    }
  }

  String _capitalise(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class AppPermissionException implements Exception {
  const AppPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
