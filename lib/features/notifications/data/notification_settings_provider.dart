import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Reading status never requests permission or initializes messaging.
/// The settings action is invoked only from a user's explicit button press.
enum DeviceNotificationStatus {
  allowed,
  quiet,
  denied,
  notRequested,
  unavailable,
}

abstract interface class NotificationSettingsGateway {
  Future<DeviceNotificationStatus> readStatus();
  Future<bool> openSettings();
}

class PlatformNotificationSettingsGateway
    implements NotificationSettingsGateway {
  @override
  Future<DeviceNotificationStatus> readStatus() async {
    if (Firebase.apps.isEmpty) return DeviceNotificationStatus.unavailable;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => DeviceNotificationStatus.allowed,
      AuthorizationStatus.provisional => DeviceNotificationStatus.quiet,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => DeviceNotificationStatus.denied,
      AuthorizationStatus.notDetermined =>
        DeviceNotificationStatus.notRequested,
    };
  }

  @override
  Future<bool> openSettings() => Geolocator.openAppSettings();
}

final notificationSettingsGatewayProvider =
    Provider<NotificationSettingsGateway>(
      (ref) => PlatformNotificationSettingsGateway(),
    );
final deviceNotificationStatusProvider =
    FutureProvider<DeviceNotificationStatus>(
      (ref) => ref.watch(notificationSettingsGatewayProvider).readStatus(),
    );
