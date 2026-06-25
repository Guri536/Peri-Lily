import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static Future<bool> requestCorePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.contacts,
      Permission.sms,
      Permission.location,
      Permission.microphone,
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);
    return allGranted;
  }
}