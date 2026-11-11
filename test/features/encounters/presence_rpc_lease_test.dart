import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mitzone/features/encounters/data/supabase_presence_repository.dart';

void main() {
  test(
    'activation caches the server lease; refresh uses only that lease and Stop clears it',
    () async {
      const user = '00000000-0000-0000-0000-000000000101';
      const lease = '00000000-0000-0000-0000-000000000401';
      final calls = <String>[];
      final bodies = <Map<String, dynamic>>[];
      final now = DateTime.now().toUtc();
      String part(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final token =
          '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': user, 'role': 'authenticated', 'aud': 'authenticated', 'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.fixture';
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-client-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/token')) {
            return http.Response(
              jsonEncode({
                'access_token': token,
                'refresh_token': 'fixture-refresh',
                'expires_in': 3600,
                'token_type': 'bearer',
                'user': {
                  'id': user,
                  'aud': 'authenticated',
                  'created_at': now.toIso8601String(),
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          final name = request.url.pathSegments.last;
          calls.add(name);
          bodies.add(
            request.body.isEmpty
                ? {}
                : (jsonDecode(request.body) as Map<String, dynamic>?) ?? {},
          );
          return http.Response(
            name == 'stop_foreground_presence'
                ? 'null'
                : jsonEncode([
                    {
                      'evidence_id': lease,
                      'context_id': 'cell:100:100',
                      'observed_start': now.toIso8601String(),
                      'observed_end': now.toIso8601String(),
                      'expires_at': now
                          .add(const Duration(minutes: 30))
                          .toIso8601String(),
                    },
                  ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.invalid',
        password: 'fixture-only',
      );
      final repository = SupabasePresenceRepository(client);
      await expectLater(
        repository.refreshForegroundPresence(latitude: 1, longitude: 1),
        throwsStateError,
      );
      expect(calls, isEmpty);
      await repository.recordForegroundPresence(latitude: 1, longitude: 1);
      await repository.refreshForegroundPresence(latitude: 1, longitude: 1);
      expect(calls, [
        'record_foreground_presence',
        'refresh_foreground_presence',
      ]);
      expect(bodies.last['p_evidence_id'], lease);
      await repository.stopForegroundPresence();
      await expectLater(
        repository.refreshForegroundPresence(latitude: 1, longitude: 1),
        throwsStateError,
      );
      expect(calls.last, 'stop_foreground_presence');
      expect(calls.length, 3);
    },
  );
}
