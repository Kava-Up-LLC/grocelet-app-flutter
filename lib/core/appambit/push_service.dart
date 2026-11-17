import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';

/// AppAmbit push notifications. The cloud sends them (start_shopping); the app only
/// registers, asks for permission once, and reacts when one arrives or is tapped.
abstract interface class PushService {
  Future<void> start();
  Future<bool> hasPermission();

  /// Shows the system prompt. Resolves with whether it was granted.
  Future<bool> requestPermission();

  void listen({required void Function(Map<String, String> data) onArrived, required void Function(Map<String, String> data) onOpened});
}

class AppAmbitPushService implements PushService {
  const AppAmbitPushService();

  @override
  Future<void> start() async {
    try {
      await PushNotificationsSdk.start();
      // Android: start() boots push with delivery off, and the OS permission alone doesn't
      // tell AppAmbit this device can receive. Turn it on whenever permission is granted
      // (also covers permission given from system Settings). Safe to repeat.
      if (await PushNotificationsSdk.hasNotificationPermission()) {
        await PushNotificationsSdk.setNotificationsEnabled(true);
      }
    } catch (_) {
      // No push credentials on this build (e.g. Android without google-services.json):
      // the list still works, it just won't get "at the store" alerts.
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      return await PushNotificationsSdk.hasNotificationPermission();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await PushNotificationsSdk.requestNotificationPermission();
      final granted = await PushNotificationsSdk.hasNotificationPermission();
      // Registers this device in AppAmbit as push-enabled (see start()).
      if (granted) await PushNotificationsSdk.setNotificationsEnabled(true);
      return granted;
    } catch (_) {
      return false;
    }
  }

  @override
  void listen({required void Function(Map<String, String> data) onArrived, required void Function(Map<String, String> data) onOpened}) {
    PushNotificationsSdk.setForegroundListener((p) => onArrived(p.data ?? const {}));
    PushNotificationsSdk.setOpenedListener((p) => onOpened(p.data ?? const {}));
  }
}
