import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/events/data/demo_events.dart';

void main() {
  const catalog = DemoEventCatalog();

  test('demo event IDs are unique', () {
    final events = catalog.getAll();
    expect(events.map((event) => event.id).toSet().length, events.length);
  });

  test('getById returns the matching event', () {
    expect(catalog.getById('tech-mixer-2026'), same(demoTechMixer));
  });

  test('getById returns null for an unknown event', () {
    expect(catalog.getById('not-real'), isNull);
  });
}
