import '../domain/event.dart';
import '../domain/event_catalog.dart';

const demoTechMixer = Event(
  id: 'tech-mixer-2026',
  title: 'Tech Mixer 2026',
  venue: 'The Innovation Hub',
  timeLabel: 'Tonight, 7:00 PM',
  category: 'Networking',
  locationLabel: 'Downtown',
  description:
      'Meet curious builders, designers, and founders in a relaxed evening '
      'made for exchanging ideas and starting genuine conversations.',
);

const demoArtOpening = Event(
  id: 'urban-art-opening',
  title: 'Urban Art Gallery Opening',
  venue: 'Metropolis Arts',
  timeLabel: 'Tonight, 6:00 PM',
  category: 'Art',
  locationLabel: 'Arts District',
  description:
      'Explore a new collection from local artists, hear the stories behind '
      'the work, and share an inspiring evening with the creative community.',
);

const demoYoga = Event(
  id: 'morning-yoga',
  title: 'Morning Yoga in the Park',
  venue: 'Central Green',
  timeLabel: 'Sun, Aug 16, 8:00 AM',
  category: 'Wellness',
  locationLabel: 'North Lawn',
  description:
      'Start the day with an accessible outdoor flow for all experience '
      'levels, followed by time to unwind and connect over fresh air.',
);

const demoJazzNight = Event(
  id: 'live-jazz-night',
  title: 'Live Jazz Night',
  venue: 'Blue Note Lounge',
  timeLabel: 'Next Fri, 9:00 PM',
  category: 'Music',
  locationLabel: 'Old Town',
  description:
      'Settle in for an intimate night of live jazz featuring a rotating '
      'local ensemble and plenty of room for conversation between sets.',
);

const List<Event> demoEvents = [
  demoTechMixer,
  demoArtOpening,
  demoYoga,
  demoJazzNight,
];

const nearbyDemoEvents = [demoTechMixer, demoYoga];
const popularDemoEvents = [demoArtOpening, demoJazzNight];

class DemoEventCatalog implements EventCatalog {
  const DemoEventCatalog();

  @override
  List<Event> getAll() => demoEvents;

  @override
  Event? getById(String id) {
    for (final event in demoEvents) {
      if (event.id == id) return event;
    }
    return null;
  }
}
