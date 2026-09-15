import 'device_token.dart';

abstract interface class DeviceTokenRepository {
  Future<void> register(String userId, DeviceToken token);
  Future<void> remove(String userId, String token);
}
