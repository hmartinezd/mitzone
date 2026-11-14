import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/domain_error.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../data/event_providers.dart';
import '../../encounters/data/foreground_location_sources.dart';
import '../../discovery/domain/nearby_provider_exception.dart';
import 'widgets/event_list_card.dart';

// Injected in tests: no test or review needs to open device settings.
final openActivityAppSettingsProvider = Provider<Future<bool> Function()>(
  (ref) => Geolocator.openAppSettings,
);
final openActivityLocationSettingsProvider = Provider<Future<bool> Function()>(
  (ref) => Geolocator.openLocationSettings,
);

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final search = TextEditingController();
  String? category;
  bool joinedOnly = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String? _settingsLabel(Object? error) {
    if (error is! ForegroundLocationException) return null;
    return switch (error.failure) {
      ForegroundLocationFailure.servicesDisabled => 'Open location settings',
      ForegroundLocationFailure.permissionPermanentlyDenied =>
        'Open app settings',
      _ => null,
    };
  }

  Future<void> _openSettings(Object? error) async {
    final open =
        error is ForegroundLocationException &&
            error.failure == ForegroundLocationFailure.servicesDisabled
        ? ref.read(openActivityLocationSettingsProvider)
        : ref.read(openActivityAppSettingsProvider);
    var opened = false;
    try {
      opened = await open();
    } catch (_) {
      // A device may not provide a settings destination.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Return here and try again after updating location access.'
              : 'Could not open settings. Open your device settings to review location access.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(nearbyEventsProvider);
    final all = eventsAsync.value ?? const [];
    final joined = ref.watch(joinedEventIdsProvider);
    final categories = {
      ...all.map((e) => e.category),
      // Keep the selected category visible after refreshed results change.
      ?category,
    }.toList();
    final query = search.text.trim().toLowerCase();
    final filtered = all
        .where(
          (e) =>
              (query.isEmpty ||
                  e.title.toLowerCase().contains(query) ||
                  e.venue.toLowerCase().contains(query)) &&
              (category == null || e.category == category) &&
              (!joinedOnly || (joined.value?.contains(e.id) ?? false)),
        )
        .toList();

    return MitzonePageBody(
      title: 'Discover nearby activities',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.explore);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover what\'s happening.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (eventsAsync.isLoading &&
              !eventsAsync.hasValue &&
              !eventsAsync.hasError)
            const Center(child: CircularProgressIndicator()),
          if (eventsAsync.hasError)
            _EventsLoadError(
              message: _eventsLoadErrorMessage(eventsAsync.error),
              onRetry: () => ref.invalidate(nearbyEventsProvider),
              settingsLabel: _settingsLabel(eventsAsync.error),
              onSettings: _settingsLabel(eventsAsync.error) == null
                  ? null
                  : () => _openSettings(eventsAsync.error),
            ),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Activity or venue',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: !joinedOnly,
                onSelected: (_) => setState(() => joinedOnly = false),
              ),
              FilterChip(
                label: const Text('Joined'),
                selected: joinedOnly,
                onSelected: (_) => setState(() => joinedOnly = true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Category', style: theme.textTheme.labelLarge),
          DropdownButton<String>(
            isExpanded: true,
            itemHeight: null,
            hint: const Text('All categories'),
            value: categories.contains(category) ? category : null,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('All categories'),
                ),
              ),
              ...categories.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(c),
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => category = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (joinedOnly && joined.isLoading) const _ParticipationLoading(),
          if (joinedOnly && joined.hasError)
            _ParticipationError(
              onRetry: () => ref.invalidate(joinedEventIdsProvider),
            ),
          if (!eventsAsync.isLoading &&
              !eventsAsync.hasError &&
              (!joinedOnly || joined.hasValue) &&
              filtered.isEmpty)
            _EmptyEvents(
              message: query.isNotEmpty || category != null
                  ? 'No activities match your filters.'
                  : joinedOnly
                  ? 'No joined activities nearby.'
                  : 'No nearby activities are available right now.',
              actionLabel: query.isNotEmpty || category != null
                  ? 'Clear filters'
                  : joinedOnly
                  ? 'Browse all activities'
                  : 'Refresh',
              onAction: () {
                if (query.isEmpty && category == null && !joinedOnly) {
                  ref.invalidate(nearbyEventsProvider);
                  return;
                }
                setState(() {
                  search.clear();
                  category = null;
                  joinedOnly = false;
                });
              },
            ),
          if (filtered.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final event = filtered[index];
                return EventListCard(
                  event: event,
                  isJoined: joined.value?.contains(event.id) ?? false,
                  onTap: () => context.push(AppRoutes.eventDetails(event.id)),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xxl),
          if (!ref.watch(productionModeProvider))
            Center(
              child: Text(
                'Showing deterministic demo events for local development.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

String _eventsLoadErrorMessage(Object? error) {
  if (error is ForegroundLocationException) {
    switch (error.failure) {
      case ForegroundLocationFailure.servicesDisabled:
        return 'Turn on Location Services to load nearby events.';
      case ForegroundLocationFailure.permissionDenied:
        return 'Allow location access while using Mitzone to load nearby events.';
      case ForegroundLocationFailure.permissionPermanentlyDenied:
        return 'Allow location access in Settings to load nearby events.';
      case ForegroundLocationFailure.temporarilyUnavailable:
        return 'Your location is temporarily unavailable. Try again.';
    }
  }
  if (error is NearbyProviderException) {
    return error.failure == NearbyProviderFailure.notConfigured
        ? 'Activities are unavailable in this environment. Try again later.'
        : 'Activities could not be loaded. Try again.';
  }
  if (error is TimeoutException) {
    return 'Nearby events took too long to load. Check your connection and try again.';
  }
  if (error is DomainError && error.code == DomainErrorCode.unavailable) {
    return '${error.message} Try again.';
  }
  return "Couldn't load nearby events. Try again.";
}

class _EventsLoadError extends StatelessWidget {
  const _EventsLoadError({
    required this.message,
    required this.onRetry,
    this.settingsLabel,
    this.onSettings,
  });

  final String message;
  final VoidCallback onRetry;
  final String? settingsLabel;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onSettings != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Exploring does not make you discoverable to other people.',
                textAlign: TextAlign.center,
              ),
              TextButton(onPressed: onSettings, child: Text(settingsLabel!)),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class _ParticipationLoading extends StatelessWidget {
  const _ParticipationLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading joined events...'),
        ],
      ),
    ),
  );
}

class _ParticipationError extends StatelessWidget {
  const _ParticipationError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        children: [
          const Text("Couldn't load joined events."),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
