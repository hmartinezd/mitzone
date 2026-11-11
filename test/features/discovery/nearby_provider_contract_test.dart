import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mitzone/features/discovery/data/google_discovery_repository.dart';
import 'package:mitzone/features/discovery/domain/nearby_provider_exception.dart';
import 'package:mitzone/features/events/data/event_repository.dart';

void main() {
  for (final places in [true, false]) {
    final name = places ? 'places' : 'activities';
    final envelope = places ? 'items' : 'events';
    Future<Object> request(int status, Object payload) async {
      final client = SupabaseClient(
        'https://staging.example.invalid',
        'client-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((req) async {
          expect(req.url.host, 'staging.example.invalid');
          expect(
            req.url.path,
            '/functions/v1/${places ? 'nearby-discovery' : 'nearby-events'}',
          );
          expect(req.method, 'POST');
          final body = jsonDecode(req.body) as Map;
          expect(body['latitude'], 40.758);
          expect(body['longitude'], -73.9855);
          return http.Response(
            jsonEncode(payload),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      return places
          ? GoogleDiscoveryRepository(
              client,
            ).getNearby(latitude: 40.758, longitude: -73.9855)
          : SupabaseEventRepository(
              client,
            ).getNearby(latitude: 40.758, longitude: -73.9855);
    }

    for (final entry in {
      401: NearbyProviderFailure.authentication,
      403: NearbyProviderFailure.authentication,
      404: NearbyProviderFailure.notConfigured,
      503: NearbyProviderFailure.notConfigured,
      502: NearbyProviderFailure.upstream,
    }.entries) {
      test('$name classifies HTTP ${entry.key} independently of GPS', () async {
        await expectLater(
          request(entry.key, {'code': 'failure'}),
          throwsA(
            isA<NearbyProviderException>()
                .having((e) => e.provider, 'provider', name)
                .having((e) => e.failure, 'failure', entry.value),
          ),
        );
      });
    }
    test('$name preserves a legitimate empty success', () async {
      expect(await request(200, {envelope: []}), isEmpty);
    });
    test(
      '$name does not disguise a broken success envelope as empty',
      () async {
        await expectLater(
          request(200, {'unexpected': []}),
          throwsA(
            isA<NearbyProviderException>().having(
              (e) => e.failure,
              'failure',
              NearbyProviderFailure.invalidResponse,
            ),
          ),
        );
      },
    );
    test('$name rejects a wholly unusable payload', () async {
      await expectLater(
        request(200, {
          envelope: [
            {'id': 'broken'},
          ],
        }),
        throwsA(
          isA<NearbyProviderException>().having(
            (e) => e.failure,
            'failure',
            NearbyProviderFailure.invalidResponse,
          ),
        ),
      );
    });
  }
}
