import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/blocking/data/block_providers.dart';
import 'package:mitzone/features/blocking/domain/block_repository.dart';
import 'package:mitzone/features/profile/data/public_peer_profiles.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';
import 'package:mitzone/features/profile/presentation/settings_placeholders.dart';
import 'package:mitzone/features/notifications/data/notification_settings_provider.dart';

class _Blocks implements BlockRepository {
  int calls = 0;
  final ids = ['a', 'b'];
  @override
  Future<void> unblock({
    required String blockerUserId,
    required String blockedUserId,
  }) async {
    calls++;
    ids.remove(blockedUserId);
  }

  @override
  Future<List<String>> getBlocked(String id) async => List.of(ids);
  @override
  Future<bool> isBlocked(String a, String b) async => false;
  @override
  Future<bool> isPairBlocked(String a, String b) async => false;
  @override
  Future<void> block({
    required String blockerUserId,
    required String blockedUserId,
  }) async {}
}

class _Settings implements NotificationSettingsGateway {
  int opens = 0;
  DeviceNotificationStatus status = DeviceNotificationStatus.denied;
  @override
  Future<DeviceNotificationStatus> readStatus() async => status;
  @override
  Future<bool> openSettings() async {
    opens++;
    return true;
  }
}

void main() {
  testWidgets(
    'blocked people have distinct names and contextual confirmation',
    (tester) async {
      final blocks = _Blocks();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) async => 'owner'),
            blockedUsersProvider.overrideWith(
              (ref) => blocks.getBlocked('owner'),
            ),
            blockRepositoryProvider.overrideWithValue(blocks),
            publicPeerProfilesProvider('a,b').overrideWith(
              (ref) async => {
                'a': const PublicProfile(id: 'a', displayName: 'Ana'),
                'b': const PublicProfile(id: 'b', displayName: 'Bea'),
              },
            ),
            publicPeerProfilesProvider('b').overrideWith(
              (ref) async => {
                'b': const PublicProfile(id: 'b', displayName: 'Bea'),
              },
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: PrivacySettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bea'), findsOneWidget);
      await tester.tap(find.text('Unblock').first);
      await tester.pumpAndSettle();
      expect(find.text('Unblock Ana?'), findsOneWidget);
      expect(blocks.calls, 0);
      await tester.tap(find.text('Keep blocked'));
      await tester.pumpAndSettle();
      expect(blocks.calls, 0);
      await tester.tap(find.text('Unblock').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Unblock'));
      await tester.pumpAndSettle();
      expect(blocks.calls, 1);
    },
  );

  testWidgets('unavailable blocked identity cannot be ambiguously unblocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedUsersProvider.overrideWith((ref) async => ['a', 'b']),
          publicPeerProfilesProvider('a,b').overrideWith((ref) async => {}),
        ],
        child: MaterialApp(home: const Scaffold(body: PrivacySettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Identity unavailable'), findsNWidgets(2));
    expect(find.text('Review'), findsNWidgets(2));
    await tester.tap(find.text('Review').first);
    await tester.pumpAndSettle();
    expect(find.text('Review blocked account'), findsOneWidget);
    expect(find.textContaining('Account reference: a'), findsOneWidget);
    await tester.tap(find.text('Keep blocked'));
    await tester.pumpAndSettle();
    expect(find.text('Retry identities'), findsOneWidget);
  });

  testWidgets('empty blocked list is explicit', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [blockedUsersProvider.overrideWith((ref) async => [])],
        child: MaterialApp(home: const Scaffold(body: PrivacySettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No blocked people'), findsOneWidget);
  });

  testWidgets(
    'notification status is read only until explicit settings action',
    (tester) async {
      final gateway = _Settings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationSettingsGatewayProvider.overrideWithValue(gateway),
          ],
          child: MaterialApp(
            home: const Scaffold(body: NotificationsSettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notifications turned off'), findsOneWidget);
      expect(gateway.opens, 0);
      await tester.tap(find.text('Open device app settings'));
      await tester.pumpAndSettle();
      expect(gateway.opens, 1);
      gateway.status = DeviceNotificationStatus.allowed;
      await tester.tap(find.text('Refresh status'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications allowed'), findsOneWidget);
    },
  );
}
