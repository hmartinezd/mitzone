enum DevicePlatform { android, ios, web }

class DeviceToken {
  const DeviceToken({required this.token, required this.platform});
  final String token;
  final DevicePlatform platform;
}
