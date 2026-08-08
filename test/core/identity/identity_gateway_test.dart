import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/local_identity_gateway.dart';
import 'package:mitzone/core/storage/local_storage.dart';

class FakeLocalStorage implements LocalStorage {
  final Map<String, dynamic> data = {};
  @override
  Future<String?> getString(String key) async => data[key] as String?;
  @override
  Future<void> setString(String key, String value) async => data[key] = value;
  @override
  Future<bool?> getBool(String key) async => data[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async => data[key] = value;
}

void main() {
  group('LocalIdentityGateway', () {
    late FakeLocalStorage storage;
    late LocalIdentityGateway gateway;

    setUp(() {
      storage = FakeLocalStorage();
      gateway = LocalIdentityGateway(storage);
    });

    test(
      'ensureIdentity() generates and persists new ID if none exists',
      () async {
        final identity = await gateway.ensureIdentity();

        expect(identity.id, isNotEmpty);
        expect(identity.type, AppIdentityType.localDevelopment);

        final persistedId = await storage.getString('local_identity.id.v1');
        expect(persistedId, identity.id);
      },
    );

    test('ensureIdentity() reuses existing ID', () async {
      const existingId = 'existing-uuid';
      await storage.setString('local_identity.id.v1', existingId);

      final identity = await gateway.ensureIdentity();

      expect(identity.id, existingId);
    });

    test('getExistingIdentity() returns null if none exists', () async {
      final identity = await gateway.getExistingIdentity();
      expect(identity, isNull);
    });

    test('concurrent ensureIdentity() calls return same ID', () async {
      final results = await Future.wait([
        gateway.ensureIdentity(),
        gateway.ensureIdentity(),
      ]);

      expect(results[0].id, results[1].id);
    });
  });
}
