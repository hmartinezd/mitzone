import 'event.dart';

abstract interface class EventCatalog {
  List<Event> getAll();
  Event? getById(String id);
}
