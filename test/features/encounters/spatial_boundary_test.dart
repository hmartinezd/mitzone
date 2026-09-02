import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/domain/presence_overlap.dart';

void main() {
  test('adjacent coarse cells are compatible', () {
    expect(PresenceOverlap.contextsCompatible('cell:10:20', 'cell:11:20'), isTrue);
  });
  test('distant cells and different event contexts are not compatible', () {
    expect(PresenceOverlap.contextsCompatible('cell:10:20', 'cell:12:20'), isFalse);
    expect(PresenceOverlap.contextsCompatible('event:a', 'event:b'), isFalse);
  });
}
