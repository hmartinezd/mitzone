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
import '../../../discovery/domain/nearby_provider_exception.dart';
import '../../../encounters/data/foreground_location_sources.dart';
import '../../../events/data/event_providers.dart';
import '../../../events/domain/event.dart';
import 'discovery_section.dart';

class HomeDiscovery extends ConsumerWidget {
  const HomeDiscovery({
    super.key,
    required this.interests,
    this.filter,
    this.onSeeAll,
    this.seeAllLabel = 'See Explore',
    this.vertical = false,
    this.query = '',
    this.onEventSelected,
  });
  final Set<String> interests;
  final DiscoveryItemType? filter;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final bool vertical;
  final String query;
  final ValueChanged<String>? onEventSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = filter == DiscoveryItemType.activity
        ? const AsyncData<List<DiscoveryItem>>([])
        : ref.watch(nearbyDiscoveryProvider(interests));
    final events = filter == DiscoveryItemType.place
        ? const AsyncData<List<Event>>([])
        : ref.watch(nearbyEventsProvider);
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
    final allItems = [
      ...eventItems.where((item) => item.imageReference != null),
      ...?places.value,
      ...eventItems.where((item) => item.imageReference == null),
    ];
    final search = query.trim().toLowerCase();
    final items = allItems
        .where(
          (item) =>
              search.isEmpty ||
              [
                item.title,
                item.context ?? '',
                ...item.category,
              ].join(' ').toLowerCase().contains(search),
        )
        .toList();
    final loading = places.isLoading || events.isLoading;
    final error = places.error ?? events.error;
    final locationError = [
      places.error,
      events.error,
    ].whereType<ForegroundLocationException>().firstOrNull;
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
            vertical: vertical,
            showDemoBadge: !production,
            onSeeAll: onSeeAll ?? () => context.go(AppRoutes.explore),
            seeAllLabel: seeAllLabel,
            actionForItem: (item) =>
                item.type == DiscoveryItemType.activity &&
                    eventItems.any((event) => event.id == item.id)
                ? () {
                    if (onEventSelected != null) {
                      onEventSelected!(item.id);
                    } else {
                      context.go(
                        AppRoutes.eventDetails(
                          item.id,
                          origin: EventDetailsOrigin.home,
                        ),
                      );
                    }
                  }
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
                        : 'Loading nearby places and activities…',
                  ),
                ),
              ],
            ),
          ),
        if (locationError != null)
          _DiscoveryFeedback(error: locationError, onRetry: retry)
        else ...[
          if (places.hasError)
            _DiscoveryFeedback(
              error: places.error!,
              providerLabel: 'Places',
              onRetry: () => ref.invalidate(nearbyDiscoveryProvider(interests)),
            ),
          if (events.hasError)
            _DiscoveryFeedback(
              error: events.error!,
              providerLabel: 'Activities',
              onRetry: () => ref.invalidate(nearbyEventsProvider),
            ),
        ],
        if (!loading && error == null && items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query.trim().isEmpty
                      ? 'Nothing nearby was found yet.'
                      : 'No nearby matches.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  query.trim().isEmpty
                      ? 'Try again later or explore another area.'
                      : 'Try another name or category.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DiscoveryFeedback extends StatelessWidget {
  const _DiscoveryFeedback({
    required this.error,
    required this.onRetry,
    this.providerLabel,
  });
  final Object error;
  final VoidCallback onRetry;
  final String? providerLabel;
  @override
  Widget build(BuildContext context) {
    final failure = error is ForegroundLocationException
        ? (error as ForegroundLocationException).failure
        : null;
    final providerFailure = error is NearbyProviderException
        ? (error as NearbyProviderException).failure
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
        providerFailure == NearbyProviderFailure.authentication
            ? 'Sign in again to load nearby discovery.'
            : providerFailure == NearbyProviderFailure.notConfigured
            ? 'Nearby discovery isn’t available yet. Please try again later.'
            : error is TimeoutException
            ? 'Nearby discovery is taking too long. Please try again.'
            : 'We couldn’t load nearby discovery right now.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (providerLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$providerLabel unavailable',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
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
