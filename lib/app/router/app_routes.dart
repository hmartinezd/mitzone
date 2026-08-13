class AppRoutes {
  /// The initial splash screen.
  static const String splash = '/';

  /// The product onboarding sequence.
  static const String onboarding = '/onboarding';

  /// The minimum profile creation screen.
  static const String createProfile = '/profile/create';

  /// Development-only visual system showcase.
  static const String showcase = '/showcase';

  /// A screen to show when application entry fails (e.g. session creation error).
  static const String entryFailure = '/entry-failure';

  /// Main navigation branch: Home
  static const String home = '/app/home';

  /// Main navigation branch: Events
  static const String events = '/app/events';

  static String eventDetails(
    String eventId, {
    EventDetailsOrigin origin = EventDetailsOrigin.direct,
  }) {
    final path = '$events/$eventId';
    return origin == EventDetailsOrigin.home ? '$path?origin=home' : path;
  }

  /// Main navigation branch: Matches
  static const String matches = '/app/matches';

  /// Main navigation branch: Chat
  static const String chat = '/app/chat';

  /// Main navigation branch: Profile
  static const String profile = '/app/profile';

  /// Profile editing screen (basic info)
  static const String profileEdit = '/app/profile/edit';

  /// Profile details screen (progressive info)
  static const String profileDetails = '/app/profile/details';

  /// Settings root screen
  static const String settings = '/app/profile/settings';

  /// Settings: Account
  static const String settingsAccount = '/app/profile/settings/account';

  /// Settings: Privacy
  static const String settingsPrivacy = '/app/profile/settings/privacy';

  /// Settings: Notifications
  static const String settingsNotifications =
      '/app/profile/settings/notifications';

  /// Settings: Terms
  static const String settingsTerms = '/app/profile/settings/terms';

  /// Settings: Privacy Policy
  static const String settingsPrivacyPolicy =
      '/app/profile/settings/privacy-policy';
}

enum EventDetailsOrigin { home, events, direct }
