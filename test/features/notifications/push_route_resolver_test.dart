import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/features/notifications/domain/push_route_resolver.dart';

void main() {
  test('maps supported notification types', () {
    expect(PushRouteResolver.resolve({'type': 'connection_request'}), AppRoutes.matches);
    expect(PushRouteResolver.resolve({'type': 'connection_accepted'}), AppRoutes.matches);
    expect(PushRouteResolver.resolve({'type': 'new_message', 'entityId': 'c1'}), '${AppRoutes.chat}/c1');
  });

  test('rejects untrusted or unsupported payloads', () {
    expect(PushRouteResolver.resolve({'type': 'unknown'}), isNull);
    expect(PushRouteResolver.resolve({'type': 'new_message'}), isNull);
    expect(PushRouteResolver.resolve({'type': 'new_message', 'entityId': 'a' * 101}), isNull);
  });
}
