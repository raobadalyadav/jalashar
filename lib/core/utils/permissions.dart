import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handling. Call [requestStartupPermissions] once
/// after sign-in and [ensure] before any feature that needs a specific
/// permission.
class AppPermissions {
  /// Non-blocking: requests notification permission on first launch.
  /// Other permissions are requested lazily when the feature is used.
  static Future<void> requestStartupPermissions() async {
    await Permission.notification.request();
  }

  /// Returns true if [permission] is granted (requests it if needed).
  static Future<bool> ensure(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> camera() => ensure(Permission.camera);
  static Future<bool> photos() => ensure(Permission.photos);
  static Future<bool> storage() => ensure(Permission.storage);
  static Future<bool> location() => ensure(Permission.locationWhenInUse);
  static Future<bool> notifications() => ensure(Permission.notification);
  static Future<bool> microphone() => ensure(Permission.microphone);
  static Future<bool> contacts() => ensure(Permission.contacts);
}
