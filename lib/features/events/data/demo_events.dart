class EventSummary {
  const EventSummary({
    required this.id,
    required this.title,
    required this.venue,
    required this.timeLabel,
    required this.category,
  });

  final String id;
  final String title;
  final String venue;
  final String timeLabel;
  final String category;
}

const demoTechMixer = EventSummary(
  id: '1',
  title: 'Tech Mixer 2026',
  venue: 'The Innovation Hub',
  timeLabel: 'Tonight, 7:00 PM',
  category: 'Networking',
);

const demoArtOpening = EventSummary(
  id: '2',
  title: 'Urban Art Gallery Opening',
  venue: 'Metropolis Arts',
  timeLabel: 'Sat, Aug 15, 6:00 PM',
  category: 'Art',
);

const demoYoga = EventSummary(
  id: '3',
  title: 'Morning Yoga in the Park',
  venue: 'Central Green',
  timeLabel: 'Sun, Aug 16, 8:00 AM',
  category: 'Wellness',
);

const demoJazzNight = EventSummary(
  id: '4',
  title: 'Live Jazz Night',
  venue: 'Blue Note Lounge',
  timeLabel: 'Next Fri, 9:00 PM',
  category: 'Music',
);

const List<EventSummary> demoEvents = [
  demoTechMixer,
  demoArtOpening,
  demoYoga,
  demoJazzNight,
];

const nearbyDemoEvents = [demoTechMixer, demoYoga];

const popularDemoEvents = [demoArtOpening, demoJazzNight];

const upcomingDemoEvents = [demoTechMixer, demoArtOpening, demoYoga];
