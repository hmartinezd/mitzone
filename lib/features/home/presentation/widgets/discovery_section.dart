import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../discovery/domain/discovery_item.dart';

class DiscoverySection extends StatelessWidget {
  const DiscoverySection({
    required this.items,
    required this.onSeeAll,
    this.actionForItem,
    this.showDemoBadge = false,
    this.seeAllLabel = 'See Explore',
    super.key,
  });
  final List<DiscoveryItem> items;
  final VoidCallback onSeeAll;
  final VoidCallback? Function(DiscoveryItem)? actionForItem;
  final bool showDemoBadge;
  final String seeAllLabel;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final title = Text(
            'Happening around you',
            style: Theme.of(context).textTheme.titleLarge,
          );
          final action = TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onSeeAll,
            child: Text(seeAllLabel),
          );
          if (constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
              300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, action],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              action,
            ],
          );
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth * .9).clamp(230.0, 360.0);
          return SingleChildScrollView(
            key: const ValueKey('home-discovery-carousel'),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  _DiscoveryCard(
                    item: items[i],
                    width: width,
                    onTap: actionForItem?.call(items[i]),
                    showDemoBadge: showDemoBadge,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.item,
    required this.width,
    required this.onTap,
    required this.showDemoBadge,
  });
  final DiscoveryItem item;
  final double width;
  final VoidCallback? onTap;
  final bool showDemoBadge;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height:
              128 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
          child: item.imageReference == null
              ? const _MissingPhoto()
              : Image.network(
                  item.imageReference!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const _MissingPhoto(loading: true),
                  errorBuilder: (_, _, _) => const _MissingPhoto(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item.category.isEmpty ? item.type.name : item.category.first)
                    .toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(item.title, style: theme.textTheme.titleLarge),
              if (item.context != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.context!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(item.subtitle!, style: theme.textTheme.bodySmall),
              ],
              if (item.distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${item.distanceKm!.toStringAsFixed(1)} km away',
                  style: theme.textTheme.labelSmall,
                ),
              ],
              if (item.source == 'google-places') ...[
                const SizedBox(height: 8),
                Text('Google Maps', style: theme.textTheme.labelSmall),
              ],
              if (item.imageAttribution != null) ...[
                const SizedBox(height: 4),
                Text(item.imageAttribution!, style: theme.textTheme.labelSmall),
              ],
              if (showDemoBadge) ...[
                const SizedBox(height: 4),
                const Text('DEMO'),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 12),
                Text(
                  'View event details',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : Semantics(
                button: true,
                label: 'View event: ${item.title}',
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto({this.loading = false});
  final bool loading;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.landscape_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              loading ? 'Loading photo…' : 'Photo unavailable',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}
