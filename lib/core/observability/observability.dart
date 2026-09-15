import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Stable, deliberately small MVP event vocabulary. Parameters must remain
/// aggregate and non-sensitive (see docs/observability.md).
abstract final class MitzoneEvents {
  static const appOpened = 'app_opened';
  static const authenticationCompleted = 'authentication_completed';
  static const profileUpdated = 'profile_updated';
  static const foregroundPresenceStarted = 'foreground_presence_started';
  static const foregroundPresenceStopped = 'foreground_presence_stopped';
  static const discoveryViewed = 'discovery_viewed';
  static const profileViewed = 'profile_viewed';
  static const connectionRequestSent = 'connection_request_sent';
  static const connectionRequestAccepted = 'connection_request_accepted';
  static const connectionRequestDeclined = 'connection_request_declined';
  static const conversationOpened = 'conversation_opened';
  static const messageSent = 'message_sent';
  static const notificationOpened = 'notification_opened';
}

abstract interface class AnalyticsReporter {
  Future<void> log(String name, {Map<String, Object>? parameters});
}

class NoopAnalyticsReporter implements AnalyticsReporter {
  const NoopAnalyticsReporter();
  @override
  Future<void> log(String name, {Map<String, Object>? parameters}) async {}
}

class FirebaseAnalyticsReporter implements AnalyticsReporter {
  FirebaseAnalyticsReporter(this._analytics);
  final FirebaseAnalytics _analytics;
  @override
  Future<void> log(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('Analytics unavailable: ${error.runtimeType}');
      unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: false));
    }
  }
}

/// Installs Crashlytics handlers without making startup or user actions fail.
Future<AnalyticsReporter> initializeObservability() async {
  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = (details) {
      unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
      return true;
    };
    return FirebaseAnalyticsReporter(FirebaseAnalytics.instance);
  } catch (error) {
    if (kDebugMode) debugPrint('Observability unavailable: ${error.runtimeType}');
    return const NoopAnalyticsReporter();
  }
}
