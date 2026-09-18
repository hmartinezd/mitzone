class Event {
  const Event({
    required this.id,
    required this.title,
    required this.venue,
    required this.timeLabel,
    required this.category,
    required this.description,
    this.locationLabel,
    this.imageKey, this.source = 'mitzone', this.sourceUrl,
    this.imageAttribution, this.startsAt, this.endsAt,
  });

  final String id;
  final String title;
  final String venue;
  final String timeLabel;
  final String category;
  final String description;
  final String? locationLabel;
  final String? imageKey;
  final String source;
  final String? sourceUrl;
  final String? imageAttribution;
  final DateTime? startsAt;
  final DateTime? endsAt;
}
