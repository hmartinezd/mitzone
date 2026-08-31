import '../../profile/domain/user_profile.dart';

abstract final class ProfileAffinity {
  static List<String> sharedInterests(UserProfile a, UserProfile b) =>
      _intersection(a.interests, b.interests);
  static List<String> sharedLanguages(UserProfile a, UserProfile b) =>
      _intersection(a.languages, b.languages);
  static bool sharedGoal(UserProfile a, UserProfile b) =>
      a.connectionGoal != null && a.connectionGoal == b.connectionGoal;
  static List<String> _intersection(List<String> a, List<String> b) {
    final normalized = {for (final value in b) _normalize(value)};
    return [for (final value in a) if (normalized.contains(_normalize(value))) value.trim()];
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
