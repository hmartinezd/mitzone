import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../data/event_providers.dart';
import 'widgets/event_list_card.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override State<EventsScreen> createState() => _EventsScreenState();
}
class _EventsScreenState extends ConsumerState<EventsScreen> {
  final search = TextEditingController();
  String? category;
  bool joinedOnly = false;
  @override void dispose() { search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(eventCatalogProvider).getAll();
    final joined = ref.watch(joinedEventIdsProvider);
    final categories = all.map((e) => e.category).toSet().toList();
    final query = search.text.trim().toLowerCase();
    final filtered = all.where((e) => (query.isEmpty || e.title.toLowerCase().contains(query) || e.venue.toLowerCase().contains(query)) && (category == null || e.category == category) && (!joinedOnly || (joined.valueOrNull?.contains(e.id) ?? false))).toList();

    return MitzonePageBody(
      title: 'Events',
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
          TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Search events or venues', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, children: [FilterChip(label: const Text('All'), selected: !joinedOnly, onSelected: (_) => setState(() => joinedOnly = false)), FilterChip(label: const Text('Joined'), selected: joinedOnly, onSelected: (_) => setState(() => joinedOnly = true)), DropdownButton<String>(hint: const Text('Category'), value: category, items: [const DropdownMenuItem(value: null, child: Text('All categories')), ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c)))], onChanged: (v) => setState(() => category = v))]),
          const SizedBox(height: AppSpacing.lg),
          if (joinedOnly && joined.isLoading) const _ParticipationLoading(),
          if (joinedOnly && joined.hasError) _ParticipationError(onRetry: () => ref.invalidate(joinedEventIdsProvider)),
          if ((!joinedOnly || joined.hasValue) && filtered.isEmpty) _EmptyEvents(message: joinedOnly ? 'No joined events match your filters.' : 'No events match your filters.', onClear: () => setState(() { search.clear(); category = null; joinedOnly = false; })),
          if (filtered.isNotEmpty) ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final event = filtered[index];
              return EventListCard(
                event: event,
                isJoined: joined.valueOrNull?.contains(event.id) ?? false,
                onTap: () => context.push(AppRoutes.eventDetails(event.id)),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'Showing demo events for local development.',
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

class _EmptyEvents extends StatelessWidget { const _EmptyEvents({required this.message, required this.onClear}); final String message; final VoidCallback onClear; @override Widget build(BuildContext context) => Center(child: Column(children: [const SizedBox(height: 24), Text(message), TextButton(onPressed: onClear, child: const Text('Clear filters'))])); }
class _ParticipationLoading extends StatelessWidget { const _ParticipationLoading(); @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(24), child: Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Loading joined events...')] ))); }
class _ParticipationError extends StatelessWidget { const _ParticipationError({required this.onRetry}); final VoidCallback onRetry; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Column(children: [const Text("Couldn't load joined events."), TextButton(onPressed: onRetry, child: const Text('Try again'))]))); }
