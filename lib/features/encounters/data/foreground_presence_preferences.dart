import '../../../core/storage/local_storage.dart';

/// Local, account-scoped UI memory, never an authority for server presence.
class ForegroundPresencePreferences {
  const ForegroundPresencePreferences(this.storage, this.userId);
  final LocalStorage storage;
  final String userId;

  String get _scope => 'foreground_presence.v2.$userId';

  // Deliberately do not migrate the old device-wide consent flag: it cannot
  // establish which account consented.
  Future<bool> hasConsent() async =>
      await storage.getBool('$_scope.consent') == true;
  Future<void> saveConsent() => storage.setBool('$_scope.consent', true);

  Future<DateTime?> lastExpiry() async {
    final raw = await storage.getString('$_scope.expiry');
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> saveExpiry(DateTime? value) => storage.setString(
    '$_scope.expiry',
    value?.toUtc().toIso8601String() ?? '',
  );
}
