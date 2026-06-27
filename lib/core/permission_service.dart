import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionsService {
  static const platform = MethodChannel('com.perilily/python_stt');

  static Future<bool> requestCorePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.contacts,
      Permission.sms,
      Permission.location,
      Permission.microphone,
      Permission.notification
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);
    if (allGranted) {
      try {
        await platform.invokeMethod('startDecoyService');
      } on PlatformException catch (e) {
        print("Failed to start decoy service: '${e.message}'.");
      }
    }
    return allGranted;
  }
}