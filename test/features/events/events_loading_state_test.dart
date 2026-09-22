import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/presentation/events_screen.dart';

void main() {
  testWidgets('event load errors replace the spinner with a retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.validated(env: AppEnvironment.local),
          ),
          nearbyEventsProvider.overrideWith((ref) async {
            throw const ForegroundLocationException(
              ForegroundLocationFailure.servicesDisabled,
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EventsScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text('Turn on Location Services to load nearby events.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });
}
