import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../data/event_providers.dart';
import '../domain/event.dart';
import 'event_category_presentation.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  const EventDetailsScreen({
    required this.eventId,
    this.origin = EventDetailsOrigin.direct,
    super.key,
  });

  final String eventId;
  final EventDetailsOrigin origin;

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _isMutating = false;

  void _back() {
    if (widget.origin == EventDetailsOrigin.home) {
      context.go(AppRoutes.home);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.events);
    }
  }

  Future<void> _setJoined(bool joined) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      final changed = await ref
          .read(eventParticipationControllerProvider)
          .setJoined(eventId: widget.eventId, joined: joined);
      if (!changed && mounted) return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              joined
                  ? "We couldn't join this event. Please try again."
                  : "We couldn't update your participation. Please try again.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventCatalogProvider).getById(widget.eventId);
    if (event == null) return const _EventNotFound();
    return _EventDetailsContent(
      event: event,
      joinedIds: ref.watch(joinedEventIdsProvider),
      isMutating: _isMutating,
      onBack: _back,
      onSetJoined: _setJoined,
      onRetryParticipation: () => ref.invalidate(joinedEventIdsProvider),
    );
  }
}

class _EventDetailsContent extends StatelessWidget {
  const _EventDetailsContent({
    required this.event,
    required this.joinedIds,
    required this.isMutating,
    required this.onBack,
    required this.onSetJoined,
    required this.onRetryParticipation,
  });

  final Event event;
  final AsyncValue<Set<String>> joinedIds;
  final bool isMutating;
  final VoidCallback onBack;
  final ValueChanged<bool> onSetJoined;
  final VoidCallback onRetryParticipation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MitzonePageBody(
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.category.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            event.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailLine(icon: Icons.access_time, text: event.timeLabel),
          const SizedBox(height: AppSpacing.sm),
          _DetailLine(icon: Icons.place_outlined, text: event.venue),
          if (event.locationLabel case final location?) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailLine(icon: Icons.map_outlined, text: location),
          ],
          const SizedBox(height: AppSpacing.xl),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              eventCategoryIcon(event.category),
              size: 64,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'About this event',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(event.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          MitzoneCard(
            child: joinedIds.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("We couldn't load your participation."),
                  TextButton(
                    onPressed: onRetryParticipation,
                    child: const Text('Try again'),
                  ),
                ],
              ),
              data: (ids) {
                final isJoined = ids.contains(event.id);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isJoined)
                      Semantics(
                        label: 'Join ${event.title}',
                        button: true,
                        excludeSemantics: true,
                        child: FilledButton.icon(
                          onPressed: isMutating
                              ? null
                              : () => onSetJoined(true),
                          icon: isMutating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Join event'),
                        ),
                      )
                    else ...[
                      Semantics(
                        label: 'Participating in ${event.title}',
                        excludeSemantics: true,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  "You're participating",
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Semantics(
                        label: 'Leave ${event.title}',
                        button: true,
                        excludeSemantics: true,
                        child: TextButton.icon(
                          onPressed: isMutating
                              ? null
                              : () => onSetJoined(false),
                          icon: isMutating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.remove_circle_outline),
                          label: const Text('Leave event'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Join to keep this event in your upcoming activities. '
                      'Participation does not verify that you were present.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(text)),
    ],
  );
}

class _EventNotFound extends StatelessWidget {
  const _EventNotFound();

  @override
  Widget build(BuildContext context) => MitzonePageBody(
    title: 'Event not found.',
    centered: true,
    child: FilledButton(
      onPressed: () => context.go(AppRoutes.events),
      child: const Text('Back to events'),
    ),
  );
}
