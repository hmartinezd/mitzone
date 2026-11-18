import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../discovery/data/discovery_providers.dart';
import '../../../discovery/domain/discovery_item.dart';
import '../../../discovery/domain/place_photo.dart';

class DiscoverySection extends StatelessWidget {
  const DiscoverySection({
    required this.items,
    required this.onSeeAll,
    this.actionForItem,
    this.showDemoBadge = false,
    this.seeAllLabel = 'See Explore',
    this.vertical = false,
    this.title = 'Happening around you',
    this.showSeeAll = true,
    super.key,
  });
  final List<DiscoveryItem> items;
  final VoidCallback onSeeAll;
  final VoidCallback? Function(DiscoveryItem)? actionForItem;
  final bool showDemoBadge;
  final String seeAllLabel;
  final bool vertical;
  final String title;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (showSeeAll)
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
        if (item.placePhoto case final photo?)
          _GooglePlacePhoto(
            key: ValueKey((photo.name, photo.signature)),
            photo: photo,
          )
        else
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
                    Text(
                      providerLabel,
                      softWrap: item.source != 'google-places',
                      style: item.source == 'google-places'
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xff5e5e5e),
                              fontSize: 12,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            )
                          : theme.textTheme.labelSmall,
                    ),
                  if (attribution != null &&
                      attribution.isNotEmpty &&
                      attribution.toLowerCase() != providerLabel?.toLowerCase())
                    Text(attribution, style: theme.textTheme.labelSmall),
                  if (showDemoBadge) const Text('DEMO'),
                  if (onTap != null)
                    Text(
                      item.type == DiscoveryItemType.place
                          ? 'View place'
                          : 'View event details',
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

class _GooglePlacePhoto extends ConsumerStatefulWidget {
  const _GooglePlacePhoto({required this.photo, super.key});

  final PlacePhoto photo;

  @override
  ConsumerState<_GooglePlacePhoto> createState() => _GooglePlacePhotoState();
}

class _GooglePlacePhotoState extends ConsumerState<_GooglePlacePhoto> {
  ui.Image? _image;
  bool _requested = false;
  bool _loading = false;

  Future<void> _load() async {
    if (_requested) return;
    setState(() {
      _requested = true;
      _loading = true;
    });
    try {
      final bytes = await ref.read(placePhotoLoaderProvider)(widget.photo);
      if (!mounted) return;
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        if (!mounted) {
          frame.image.dispose();
          return;
        }
        setState(() => _image = frame.image);
      } finally {
        codec.dispose();
      }
    } catch (_) {
      // The place remains readable with the existing unavailable state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _openLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Some devices do not have a handler for external links.
    }
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Could not open the Google Maps link')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: image != null
              ? RawImage(image: image, fit: BoxFit.cover)
              : !_requested
              ? ColoredBox(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Load place photo'),
                    ),
                  ),
                )
              : _MissingPhoto(loading: _loading),
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final author in widget.photo.authors)
                  if (author.profileUri case final uri?)
                    TextButton(
                      onPressed: () => _openLink(uri),
                      child: Text(author.displayName),
                    )
                  else
                    Text(author.displayName, style: theme.textTheme.labelSmall),
                if (widget.photo.googleMapsUri case final uri?)
                  TextButton(
                    onPressed: () => _openLink(uri),
                    child: const Text('View photo on Google Maps'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
