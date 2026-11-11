import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';

void main() {
  test('production accepts structurally valid non-mock IDs', () {
    expect(
      matchProfileRouteParametersAreValid(
        userId: 'supabase-user-9',
        encounterId: 'encounter-1',
        production: true,
        localUserIds: const ['jose'],
      ),
      isTrue,
    );
  });

  test('local mode keeps deterministic mock validation', () {
    expect(
      matchProfileRouteParametersAreValid(
        userId: 'unknown',
        encounterId: 'encounter-1',
        production: false,
        localUserIds: const ['jose'],
      ),
      isFalse,
    );
  });

  test('missing route parameters remain invalid', () {
    expect(
      matchProfileRouteParametersAreValid(
        userId: '',
        encounterId: 'encounter-1',
        production: true,
        localUserIds: const [],
      ),
      isFalse,
    );
  });
}
