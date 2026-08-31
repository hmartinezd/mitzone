/// Centralized validation logic for user profiles.
abstract final class ProfileValidation {
  static bool hasMinimumProfile(String? displayName) =>
      isValidDisplayName(displayName);
  /// Minimum display name length.
  static const int minDisplayNameLength = 2;

  /// Maximum display name length.
  static const int maxDisplayNameLength = 50;

  /// Maximum bio length.
  static const int maxBioLength = 240;

  /// Maximum city length.
  static const int maxCityLength = 80;

  /// Maximum number of items in interests or languages.
  static const int maxListItems = 10;

  /// Maximum length for a single list item.
  static const int maxListItemLength = 30;

  /// Validates a display name.
  static bool isValidDisplayName(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.length >= minDisplayNameLength &&
        trimmed.length <= maxDisplayNameLength;
  }

  /// Validates a bio.
  static bool isValidBio(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.length <= maxBioLength;
  }

  /// Validates a city.
  static bool isValidCity(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.length <= maxCityLength;
  }

  /// Validates an interest or language list item.
  static bool isValidListItem(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxListItemLength;
  }

  /// Normalizes a string list (interests/languages).
  ///
  /// This performs trimming, removal of empties, and case-insensitive deduplication.
  /// It does NOT truncate or filter based on validity; that is handled by the UI validation.
  static List<String> normalizeList(List<String> items) {
    final uniqueItems = <String>{};
    final result = <String>[];

    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;

      final key = trimmed.toLowerCase();
      if (!uniqueItems.contains(key)) {
        uniqueItems.add(key);
        result.add(trimmed);
      }
    }

    return result;
  }
}
