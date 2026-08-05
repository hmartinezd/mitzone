import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/bootstrap.dart';

void main() {
  group('Bootstrap', () {
    testWidgets('unconfigured mode does not call Supabase initialization', (
      tester,
    ) async {
      bool initialized = false;

      await bootstrap(
        supabaseInitializer: ({required url, required publishableKey}) async {
          initialized = true;
        },
      );

      // In tests, String.fromEnvironment defaults to empty strings, so it should be unconfigured
      expect(initialized, isFalse);
    });

    // Note: Testing 'configured' mode is hard without being able to mock String.fromEnvironment.
    // In Flutter tests, we can't easily set --dart-define values for a specific test.
  });
}
