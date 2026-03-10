import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  /// Requests microphone permission, returning true if granted.
  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> get isMicrophoneGranted async =>
      (await Permission.microphone.status).isGranted;

  /// Opens device app settings (used when permission is permanently denied).
  Future<void> openSettings() => openAppSettings();
}
