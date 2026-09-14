import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../discovery/domain/discovery_item.dart';

class DiscoverySection extends StatelessWidget {
  const DiscoverySection({
    required this.items,
    required this.onSeeAll,
    required this.onItemTap,
    this.showDemoBadge = false,
    super.key,
  });
  final List<DiscoveryItem> items;
  final VoidCallback onSeeAll;
  final ValueChanged<DiscoveryItem> onItemTap;
  final bool showDemoBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Happening around you', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ]),
      SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => _DiscoveryCard(
            item: items[index],
            showDemoBadge: showDemoBadge,
            onTap: () => onItemTap(items[index]),
          ),
        ),
      ),
    ]);
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.item, required this.onTap, required this.showDemoBadge});
  final DiscoveryItem item;
  final VoidCallback onTap;
  final bool showDemoBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = item.category.isEmpty ? item.type.name : item.category.first;
    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (item.imageReference != null)
                SizedBox(height: 70, width: double.infinity, child: Image.network(item.imageReference!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink())),
              Text(category.toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (item.context != null) Text(item.context!, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (item.subtitle != null) Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (item.distanceKm != null) Text('${item.distanceKm!.toStringAsFixed(1)} km away'),
              if (item.source == 'google-places')
                Text('Google Maps', style: theme.textTheme.labelSmall),
              if (showDemoBadge) const Text('DEMO'),
            ]),
          ),
        ),
      ),
    );
  }
}
