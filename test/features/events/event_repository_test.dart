import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/events/data/event_repository.dart';
void main() {
  test('normalizes external event and preserves metadata', () {
    final e=normalizeExternalEvent({'id':'ticketmaster:abc','title':'Festival','venue':'Town Hall','categories':['Music'],'sourceUrl':'https://example.test/event','startsAt':'2026-09-17T19:00:00Z'});
    expect(e?.id,'ticketmaster:abc'); expect(e?.sourceUrl,'https://example.test/event'); expect(e?.startsAt,isNotNull);
  });
  test('malformed provider data is ignored', () { expect(normalizeExternalEvent({'id':'x'}),isNull); expect(normalizeExternalEvent({'id':'','title':'x','venue':'y'}),isNull); });
}
