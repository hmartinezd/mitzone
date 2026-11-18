import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import 'package:mitzone/features/discovery/data/google_discovery_repository.dart';
import 'package:mitzone/features/discovery/domain/discovery_item.dart';
import 'package:mitzone/features/discovery/domain/place_photo.dart';
import 'package:mitzone/features/home/presentation/widgets/discovery_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'parses optional photo and author data and requests media on demand',
    () async {
      final expiresAt = DateTime.now()
          .add(const Duration(minutes: 2))
          .millisecondsSinceEpoch;
      var mediaCalls = 0;
      final client = SupabaseClient(
        'https://staging.example.invalid',
        'fixture-client-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/functions/v1/nearby-discovery');
          final body = jsonDecode(request.body) as Map;
          if (body['action'] == 'photo') {
            mediaCalls++;
            expect(body, {
              'action': 'photo',
              'name': 'places/fixture/photos/fixture',
              'signature': 'fixture-signature',
              'expiresAt': expiresAt,
            });
            if (mediaCalls == 2) {
              return http.Response(
                '{}',
                502,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response.bytes(
              [1, 2, 3],
              200,
              headers: {'content-type': 'application/octet-stream'},
            );
          }
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'google:without-photo',
                  'title': 'Without photo',
                  'categories': [],
                },
                {
                  'id': 'google:with-photo',
                  'title': 'With photo',
                  'categories': [],
                  'photo': {
                    'name': 'places/fixture/photos/fixture',
                    'expiresAt': expiresAt,
                    'signature': 'fixture-signature',
                    'googleMapsUri':
                        'https://www.google.com/maps/example-photo',
                    'authors': [
                      {
                        'displayName': 'Fixture photographer',
                        'uri': 'https://maps.google.com/maps/contrib/123',
                        'photoUri':
                            'https://lh3.googleusercontent.com/fixture-avatar',
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = GoogleDiscoveryRepository(client);
      final places = await repository.getNearby(
        latitude: 40.75,
        longitude: -73.98,
      );
      expect(mediaCalls, 0);
      expect(
        places
            .singleWhere((place) => place.id == 'google:without-photo')
            .placePhoto,
        isNull,
      );
      final photo = places
          .singleWhere((place) => place.id == 'google:with-photo')
          .placePhoto!;
      expect(photo.googleMapsUri?.path, '/maps/example-photo');
      expect(photo.authors.single.displayName, 'Fixture photographer');
      expect(photo.authors.single.profileUri?.host, 'maps.google.com');
      expect(photo.authors.single.avatarUri?.host, 'lh3.googleusercontent.com');
      expect(await repository.loadPhoto(photo), [1, 2, 3]);
      await expectLater(
        repository.loadPhoto(photo),
        throwsA(isA<FunctionsHttpException>()),
      );
    },
  );

  testWidgets('loading failure restores the honest photo placeholder', (
    tester,
  ) async {
    final result = Completer<Uint8List>();
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placePhotoLoaderProvider.overrideWithValue((photo) {
            requests++;
            return result.future;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DiscoverySection(
              onSeeAll: () {},
              items: const [
                DiscoveryItem(
                  id: 'fixture',
                  source: 'google-places',
                  type: DiscoveryItemType.place,
                  title: 'Fixture Place',
                  category: [],
                  placePhoto: PlacePhoto(
                    name: 'places/fixture/photos/fixture',
                    signature: 'fixture-signature',
                    expiresAt: 0,
                    authors: [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(requests, 0);
    await tester.tap(find.text('Load place photo'));
    await tester.pump();
    expect(requests, 1);
    expect(find.text('Loading photo…'), findsOneWidget);
    result.completeError(StateError('fixture failure'));
    await tester.pumpAndSettle();
    expect(find.text('Photo unavailable'), findsOneWidget);
    expect(find.text('Fixture Place'), findsOneWidget);
    expect(requests, 1);
  });
}
