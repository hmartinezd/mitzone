import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../domain/device_token.dart';
import '../domain/device_token_repository.dart';
import '../domain/push_route_resolver.dart';

/// Best-effort FCM lifecycle; invoke only after authenticated app readiness.
class PushNotificationService {
  PushNotificationService(this.repository, this.userId);
  final DeviceTokenRepository repository;
  final String userId;
  StreamSubscription<String>? _refresh;
  final List<StreamSubscription<dynamic>> _messageSubscriptions = [];
  String? _token;
  Future<void> Function(Map<String, dynamic>)? onTap;
  Future<void> Function()? onForeground;

  Future<AuthorizationStatus> start() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      _messageSubscriptions.add(FirebaseMessaging.onMessage.listen((_) => onForeground?.call()));
      _messageSubscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((message) => onTap?.call(message.data)));
      final initial = await messaging.getInitialMessage();
      if (initial != null) onTap?.call(initial.data);
      final settings = await messaging.requestPermission(provisional: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied || settings.authorizationStatus == AuthorizationStatus.notDetermined) return settings.authorizationStatus;
      await _register(await messaging.getToken());
      _refresh = messaging.onTokenRefresh.listen(_register);
      return settings.authorizationStatus;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Push setup unavailable: ${error.runtimeType}');
      return AuthorizationStatus.notDetermined;
    }
  }

  static String? route(Map<String, dynamic> data) => PushRouteResolver.resolve(data);

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) return;
    await repository.register(userId, DeviceToken(token: token, platform: defaultTargetPlatform == TargetPlatform.iOS ? DevicePlatform.ios : DevicePlatform.android));
    _token = token;
  }

  Future<void> dispose() async {
    await _refresh?.cancel();
    for (final subscription in _messageSubscriptions) await subscription.cancel();
    if (_token != null) await repository.remove(userId, _token!);
  }
}
