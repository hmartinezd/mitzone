import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_providers.dart';
import '../../encounters/data/foreground_location_sources.dart';
import '../../encounters/data/presence_providers.dart';
import '../../encounters/domain/location_observation.dart';

const discoveryRequestTimeout = Duration(seconds: 20);

/// One foreground observation shared by discovery queries, never presence
/// evidence. No polling, background stream, or persistent coordinate cache.
final discoveryLocationProvider = FutureProvider.autoDispose<LocationObservation>(
  (ref) {
    ref.watch(authSessionProvider.select((session) => session.value?.user.id));
    return ref
        .watch(locationObservationSourceProvider)
        .observeForeground()
        .timeout(
          discoveryRequestTimeout,
          onTimeout: () {
            if (kDebugMode) {
              developer.log(
                'Foreground location observation timed out after '
                '${discoveryRequestTimeout.inMilliseconds} ms',
                name: 'mitzone.location',
              );
            }
            throw const ForegroundLocationException(
              ForegroundLocationFailure.temporarilyUnavailable,
            );
          },
        );
  },
  // Permission denial must wait for an explicit retry, not automatic retries.
  retry: (_, _) => null,
);
