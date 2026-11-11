import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/splash/presentation/splash_screen.dart';
import 'package:mitzone/shared/widgets/mitzone_brand.dart';
import 'package:mitzone/shared/widgets/mitzone_loading_indicator.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('renders brand mark, product name, and loading indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(onCompleted: () {})),
      );

      expect(find.byType(MitzoneBrand), findsOneWidget);
      expect(find.text('Mitzone'), findsOneWidget);
      expect(find.byType(MitzoneLoadingIndicator), findsOneWidget);

      // Verify no debug info is shown
      expect(find.textContaining('Environment'), findsNothing);
      expect(find.textContaining('Supabase'), findsNothing);

      // Clear timers
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('invokes onCompleted exactly once after animation sequence', (
      WidgetTester tester,
    ) async {
      int completedCount = 0;

      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(onCompleted: () => completedCount++)),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(completedCount, 0);

      await tester.pump(const Duration(seconds: 5));
      expect(completedCount, 1);

      await tester.pump();
      expect(completedCount, 1);
    });

    testWidgets('completes faster in reduced-motion mode', (
      WidgetTester tester,
    ) async {
      int completedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SplashScreen(onCompleted: () => completedCount++),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(completedCount, 0);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(completedCount, 1);
    });

    testWidgets('handles different viewports without overflow', (
      WidgetTester tester,
    ) async {
      final viewports = [
        const Size(320, 480), // Small phone
        const Size(414, 896), // Standard phone
        const Size(1024, 768), // Tablet
        const Size(896, 414), // Landscape phone
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(home: SplashScreen(onCompleted: () {})),
        );

        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 5));
      }
    });

    testWidgets('handles 2.0 text scaling without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: SplashScreen(onCompleted: () {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('has meaningful semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(onCompleted: () {})),
      );

      // Advance time to make components visible
      await tester.pump(const Duration(seconds: 2));

      // Verify that semantics-bearing widgets are present
      expect(find.byType(MitzoneBrand), findsOneWidget);
      expect(find.byType(MitzoneLoadingIndicator), findsOneWidget);

      handle.dispose();
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
