import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../discovery/data/discovery_location_provider.dart';
import '../../../discovery/data/discovery_providers.dart';
import '../../../discovery/domain/discovery_item.dart';
import '../../../encounters/data/foreground_location_sources.dart';
import '../../../events/data/event_providers.dart';
import 'discovery_section.dart';

class HomeDiscovery extends ConsumerWidget {
  const HomeDiscovery({super.key, required this.interests});
  final Set<String> interests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(nearbyDiscoveryProvider(interests));
    final events = ref.watch(nearbyEventsProvider);
    final production = ref.watch(productionModeProvider);
    final eventItems = [
      for (final event in events.value ?? [])
        DiscoveryItem(
          id: event.id,
          source: event.source,
          type: DiscoveryItemType.activity,
          title: event.title,
          category: [event.category],
          context: event.venue,
          subtitle: event.timeLabel,
          startsAt: event.startsAt,
          endsAt: event.endsAt,
          imageReference: Uri.tryParse(event.imageKey ?? '')?.scheme == 'https'
              ? event.imageKey
              : null,
          imageAttribution: event.imageKey == null
              ? null
              : event.imageAttribution,
        ),
    ];
    final items = [
      ...eventItems.where((item) => item.imageReference != null),
      ...?places.value,
      ...eventItems.where((item) => item.imageReference == null),
    ];
    final loading = places.isLoading || events.isLoading;
    final error = places.error ?? events.error;
    final locating =
        production && loading && ref.watch(discoveryLocationProvider).isLoading;
    void retry() {
      if (error is ForegroundLocationException) {
        ref.invalidate(discoveryLocationProvider);
      }
      if (places.hasError) ref.invalidate(nearbyDiscoveryProvider(interests));
      if (events.hasError) ref.invalidate(nearbyEventsProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partial provider failure must not hide successfully loaded real data.
        if (items.isNotEmpty)
          DiscoverySection(
            items: items,
            showDemoBadge: !production,
            onSeeAll: () => context.go(AppRoutes.events),
            actionForItem: (item) =>
                item.type == DiscoveryItemType.activity &&
                    eventItems.any((event) => event.id == item.id)
                ? () => context.go(
                    AppRoutes.eventDetails(
                      item.id,
                      origin: EventDetailsOrigin.home,
                    ),
                  )
                : null,
          ),
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locating
                        ? 'Finding nearby location…'
                        : 'Loading nearby places and events…',
                  ),
                ),
              ],
            ),
          ),
        if (error != null) _DiscoveryFeedback(error: error, onRetry: retry),
        if (!loading && error == null && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Nothing nearby was found yet.'),
          ),
      ],
    );
  }
}

class _DiscoveryFeedback extends StatelessWidget {
  const _DiscoveryFeedback({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error is ForegroundLocationException
        ? (error as ForegroundLocationException).failure
        : null;
    final message = switch (failure) {
      ForegroundLocationFailure.permissionDenied =>
        'Location permission was denied. You can retry when you’re ready.',
      ForegroundLocationFailure.permissionPermanentlyDenied =>
        'Location permission is off. Enable it in Settings to discover nearby places and events.',
      ForegroundLocationFailure.servicesDisabled =>
        'Location services are off. Turn them on to discover nearby places and events.',
      ForegroundLocationFailure.temporarilyUnavailable =>
        'Your location is unavailable right now. Please try again.',
      null =>
        error is TimeoutException
            ? 'Nearby discovery is taking too long. Please try again.'
            : 'We couldn’t load nearby discovery right now.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          Wrap(
            spacing: 8,
            children: [
              if (failure ==
                  ForegroundLocationFailure.permissionPermanentlyDenied)
                TextButton(
                  onPressed: () => Geolocator.openAppSettings(),
                  child: const Text('Settings'),
                ),
              if (failure == ForegroundLocationFailure.servicesDisabled)
                TextButton(
                  onPressed: () => Geolocator.openLocationSettings(),
                  child: const Text('Settings'),
                ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ],
      ),
    );
  }
}
