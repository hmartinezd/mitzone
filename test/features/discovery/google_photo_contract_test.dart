import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mitzone/features/discovery/data/google_discovery_repository.dart';

void main() {
  for (final photo in [
    null,
    'https://lh3.googleusercontent.com/fixture',
    'https://evil.invalid/photo',
    'https://lh3.googleusercontent.com/fixture?key=secret',
  ]) {
    test('places retain data and safely parse optional photo $photo', () async {
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (req) async => http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'google:fixture',
                  'title': 'Fixture cafe',
                  'categories': ['food'],
                  'imageReference': photo,
                  'imageAttribution': 'Fixture author',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(client.dispose);
      final items = await GoogleDiscoveryRepository(
        client,
      ).getNearby(latitude: 27.94, longitude: -82.27);
      expect(items.single.title, 'Fixture cafe');
      expect(
        items.single.imageReference,
        photo == 'https://lh3.googleusercontent.com/fixture' ? photo : null,
      );
      expect(items.single.imageAttribution, 'Fixture author');
    });
  }
}
