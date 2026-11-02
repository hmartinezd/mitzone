import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../discovery/domain/discovery_item.dart';

class DiscoverySection extends StatelessWidget {
  const DiscoverySection({
    required this.items,
    required this.onSeeAll,
    this.actionForItem,
    this.showDemoBadge = false,
    super.key,
  });
  final List<DiscoveryItem> items;
  final VoidCallback onSeeAll;
  final VoidCallback? Function(DiscoveryItem)? actionForItem;
  final bool showDemoBadge;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Happening around you',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onSeeAll,
            child: const Text('See all'),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth * .84).clamp(230.0, 360.0);
          return SingleChildScrollView(
            key: const ValueKey('home-discovery-carousel'),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.md),
                  _DiscoveryCard(
                    item: items[index],
                    width: width,
                    showDemoBadge: showDemoBadge,
                    onTap: actionForItem?.call(items[index]),
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
    final category = item.category.isEmpty
        ? item.type.name
        : item.category.first;
    final image = item.imageReference;
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: width * .68,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image == null
                  ? const _MissingPhoto()
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const _MissingPhoto(loading: true),
                      errorBuilder: (_, _, _) => const _MissingPhoto(),
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00070C14),
                      Color(0x22070C14),
                      Color(0xE6070C14),
                    ],
                    stops: [0, .45, 1],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8FD4FF),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFF101D2D),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.context != null)
                Text(
                  item.context!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFDAE1EA),
                  ),
                ),
              if (item.subtitle != null) ...[
                if (item.context != null) const SizedBox(height: 2),
                Text(
                  item.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFDAE1EA),
                  ),
                ),
              ],
              if (item.distanceKm != null) ...[
                if (item.context != null || item.subtitle != null)
                  const SizedBox(height: 5),
                Text(
                  '${item.distanceKm!.toStringAsFixed(1)} km away',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
              if (item.source == 'google-places') ...[
                if (item.context != null ||
                    item.subtitle != null ||
                    item.distanceKm != null)
                  const SizedBox(height: 5),
                Text(
                  'Google Maps',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
              if (item.imageAttribution != null) ...[
                if (item.context != null ||
                    item.subtitle != null ||
                    item.distanceKm != null ||
                    item.source == 'google-places')
                  const SizedBox(height: 5),
                Text(
                  item.imageAttribution!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFDAE1EA),
                  ),
                ),
              ],
              if (showDemoBadge) const Text('DEMO'),
            ],
          ),
        ),
      ],
    );
    return SizedBox(
      width: width,
      child: Card(
        color: const Color(0xFF101D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF34475C)),
        ),
        clipBehavior: Clip.antiAlias,
        // Informational places have no tap handler, ripple, button semantics,
        // or decorative CTA. Only existing event destinations are actionable.
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
    color: const Color(0xFF122238),
    child: Align(
      alignment: const Alignment(0, -.65),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.landscape_outlined,
              size: 36,
              color: Color(0xFF8199B5),
            ),
            const SizedBox(height: 8),
            Text(
              loading ? 'Loading photo…' : 'Photo unavailable',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: const Color(0xFFB4C1D0)),
            ),
          ],
        ),
      ),
    ),
  );
}
