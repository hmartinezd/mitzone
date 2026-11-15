import 'package:flutter/material.dart';

import '../../../discovery/domain/discovery_item.dart';

class DiscoverySection extends StatelessWidget {
  const DiscoverySection({
    required this.items,
    required this.onSeeAll,
    this.actionForItem,
    this.showDemoBadge = false,
    this.seeAllLabel = 'See Explore',
    this.vertical = false,
    super.key,
  });
  final List<DiscoveryItem> items;
  final VoidCallback onSeeAll;
  final VoidCallback? Function(DiscoveryItem)? actionForItem;
  final bool showDemoBadge;
  final String seeAllLabel;
  final bool vertical;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Text(
            'Happening around you',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          TextButton(onPressed: onSeeAll, child: Text(seeAllLabel)),
        ],
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          if (vertical) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  _DiscoveryCard(
                    item: items[i],
                    width: constraints.maxWidth,
                    onTap: actionForItem?.call(items[i]),
                    showDemoBadge: showDemoBadge,
                  ),
                ],
              ],
            );
          }
          final width = (constraints.maxWidth * .92).clamp(200.0, 360.0);
          return SingleChildScrollView(
            key: const ValueKey('home-discovery-carousel'),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
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
    final image = Uri.tryParse(item.imageReference ?? '');
    final hasPhoto = image?.scheme == 'https' && image!.host.isNotEmpty;
    final providerLabel = switch (item.source) {
      'google-places' => 'Google Maps',
      'ticketmaster' => 'Ticketmaster',
      _ => null,
    };
    final attribution = item.imageAttribution?.trim();
    final metadata = [
      if (item.context?.isNotEmpty == true) item.context!,
      if (item.distanceKm != null)
        '${item.distanceKm!.toStringAsFixed(1)} km away',
    ];
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: hasPhoto
              ? Image.network(
                  item.imageReference!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const _MissingPhoto(loading: true),
                  errorBuilder: (_, _, _) => const _MissingPhoto(),
                )
              : const _MissingPhoto(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: theme.textTheme.headlineSmall),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(metadata.join(' · '), style: theme.textTheme.bodySmall),
              ],
              if (item.subtitle?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  item.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (providerLabel != null)
                    Text(providerLabel, style: theme.textTheme.labelSmall),
                  if (attribution != null &&
                      attribution.isNotEmpty &&
                      attribution.toLowerCase() != providerLabel?.toLowerCase())
                    Text(attribution, style: theme.textTheme.labelSmall),
                  if (showDemoBadge) const Text('DEMO'),
                  if (onTap != null)
                    Text(
                      'View event details',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MediaQuery.textScalerOf(context).scale(1) < 1.5) ...[
              Icon(
                Icons.landscape_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 8),
            ],
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
