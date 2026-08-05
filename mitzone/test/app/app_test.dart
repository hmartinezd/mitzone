import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/app/app.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/foundation/presentation/foundation_screen.dart';

void main() {
  testWidgets('App renders FoundationScreen initially', (tester) async {
    final config = AppConfig.fromEnvironment();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const MitzoneApp(),
      ),
    );

    expect(find.byType(FoundationScreen), findsOneWidget);
    expect(find.text('Mitzone'), findsOneWidget);
    expect(
      find.text('The best connections begin in the real world.'),
      findsOneWidget,
    );
  });
}
