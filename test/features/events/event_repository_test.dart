import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/events/data/event_repository.dart';
void main() {
  test('normalizes external event and preserves metadata', () {
    final e=normalizeExternalEvent({'id':'ticketmaster:abc','title':'Festival','venue':'Town Hall','categories':['Music'],'source':'ticketmaster','sourceUrl':'https://example.test/event','imageAttribution':'Ticketmaster','startsAt':'2026-09-17T19:00:00Z','endsAt':'2026-09-17T21:00:00Z'});
    expect(e?.id,'ticketmaster:abc'); expect(e?.source,'ticketmaster'); expect(e?.sourceUrl,'https://example.test/event'); expect(e?.imageAttribution,'Ticketmaster'); expect(e?.startsAt,isNotNull); expect(e?.endsAt,isNotNull); expect(e?.timeLabel,'9/17/2026 at 3:00 PM – 5:00 PM');
  });
  test('formats date-only provider values without inventing a time', () {
    expect(formatProviderEventTime('2026-09-17', null), '9/17/2026');
  });
  test('malformed provider data is ignored', () { expect(normalizeExternalEvent({'id':'x'}),isNull); expect(normalizeExternalEvent({'id':'','title':'x','venue':'y'}),isNull); });
}
