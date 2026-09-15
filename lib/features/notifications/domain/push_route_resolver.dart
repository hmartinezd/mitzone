import 'package:mitzone/app/router/app_routes.dart';

class PushRouteResolver {
  static String? resolve(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final entity = data['entityId']?.toString();
    if (type == 'connection_request' || type == 'connectionRequest') return AppRoutes.matches;
    if (type == 'connection_accepted' || type == 'connectionAccepted') return AppRoutes.matches;
    if (type == 'new_message' || type == 'newMessage') {
      if (entity == null || entity.isEmpty || entity.length > 100) return null;
      return '${AppRoutes.chat}/$entity';
    }
    return null;
  }
}
