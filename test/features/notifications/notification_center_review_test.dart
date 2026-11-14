import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/notifications/data/notification_providers.dart';
import 'package:mitzone/features/notifications/domain/local_notification.dart';
import 'package:mitzone/features/notifications/domain/notification_repository.dart';
import 'package:mitzone/features/notifications/presentation/notification_center_screen.dart';
import 'package:mitzone/features/profile/data/public_peer_profiles.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';

final _notification = LocalNotification(
  id: 'n',
  type: LocalNotificationType.connectionRequest,
  userId: 'me',
  timestamp: DateTime(2026, 11, 12, 12, 30),
  entityId: 'r',
  destination: '/target',
  actorUserId: 'peer',
);

Widget _fixture(_Notifications repository, Widget child) => ProviderScope(
  overrides: [
    currentUserIdProvider.overrideWithValue(const AsyncData('me')),
    notificationRepositoryProvider.overrideWithValue(repository),
    publicPeerProfilesProvider.overrideWith(
      (ref, key) async => {
        'peer': const PublicProfile(id: 'peer', displayName: 'Sofia'),
      },
    ),
  ],
  child: child,
);

void main() {
  testWidgets('empty notification center hides mark-all action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _fixture(
        _Notifications([]),
        const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No notifications yet.'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('date actor and unread state are readable', (tester) async {
    await tester.pumpWidget(
      _fixture(
        _Notifications([_notification]),
        const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Sofia\n'), findsOneWidget);
    expect(find.textContaining('Unread'), findsOneWidget);
    expect(find.textContaining('.000'), findsNothing);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets(
    'mark all read guards repeated actions and supports failure retry',
    (tester) async {
      final repository = _Notifications([_notification]);
      await tester.pumpWidget(
        _fixture(
          repository,
          const MaterialApp(home: NotificationCenterScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark all read'));
      await tester.pump();
      expect(repository.allCalls, 1);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Marking…'))
            .onPressed,
        isNull,
      );
      repository.pending!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not mark notifications as read. Try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Mark all read'));
      await tester.pump();
      repository.items = [_notification.copyWith(read: true)];
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(repository.allCalls, 2);
      expect(find.text('Mark all read'), findsNothing);
    },
  );

  testWidgets('read-state failure does not swallow navigation', (tester) async {
    final repository = _Notifications([_notification])..failMark = true;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NotificationCenterScreen()),
        GoRoute(
          path: '/target',
          builder: (_, _) => const Scaffold(body: Text('Target screen')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _fixture(repository, MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New connection request'));
    await tester.pumpAndSettle();
    expect(find.text('Target screen'), findsOneWidget);
    expect(find.textContaining('could not mark it as read'), findsOneWidget);
  });

  testWidgets('list read error offers retry', (tester) async {
    final repository = _Notifications([])..failRead = true;
    await tester.pumpWidget(
      _fixture(repository, const MaterialApp(home: NotificationCenterScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    repository.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No notifications yet.'), findsOneWidget);
  });
}

class _Notifications implements NotificationRepository {
  _Notifications(this.items);
  List<LocalNotification> items;
  bool failRead = false;
  bool failMark = false;
  int allCalls = 0;
  Completer<void>? pending;
  @override
  Future<List<LocalNotification>> getForUser(String userId) async {
    if (failRead) throw StateError('unavailable');
    return items;
  }

  @override
  Future<void> add(LocalNotification notification) async {}
  @override
  Future<void> markRead(String userId, String id) async {
    if (failMark) throw StateError('unavailable');
  }

  @override
  Future<void> markAllRead(String userId) {
    allCalls++;
    pending = Completer<void>();
    return pending!.future;
  }
}
