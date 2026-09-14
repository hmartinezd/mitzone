enum DiscoveryItemType { place, activity }

class DiscoveryItem {
  const DiscoveryItem({
    required this.id,
    required this.source,
    required this.type,
    required this.title,
    required this.category,
    this.imageReference,
    this.context,
    this.distanceKm,
    this.startsAt,
    this.endsAt,
    this.subtitle,
  });

  final String id;
  final String source;
  final DiscoveryItemType type;
  final String title;
  final List<String> category;
  final String? imageReference;
  final String? context;
  final double? distanceKm;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? subtitle;
}
