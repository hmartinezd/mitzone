class AppRoutes {
  /// The initial splash screen.
  static const String splash = '/';

  /// The product onboarding sequence.
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String terms = '/terms';
  static const String privacyPolicy = '/privacy-policy';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  /// Development-only visual system showcase.
  static const String showcase = '/showcase';

  /// A screen shown when authenticated application entry cannot be resolved.
  static const String entryFailure = '/entry-failure';

  /// Main navigation branch: Home
  static const String home = '/app/home';

  /// Main navigation branch: Explore (live places and activities).
  static const String explore = '/app/explore';
  static const String exploreActivities = '/app/explore/activities';

  /// Legacy activity-catalog links retained inside the Explore branch.
  static const String events = '/app/events';

  static String eventDetails(
    String eventId, {
    EventDetailsOrigin origin = EventDetailsOrigin.direct,
  }) {
    final path = '$events/$eventId';
    return origin == EventDetailsOrigin.home ? '$path?origin=home' : path;
  }

  /// Main navigation branch: Nearby (encounters, requests and connections).
  static const String nearby = '/app/nearby';
  static const String nearbyConnections = '/app/nearby/connections';

  /// Legacy encounter links retained inside the Nearby branch.
  static const String matches = '/app/matches';

  /// Messages are a protected root destination, outside the bottom tabs.
  static const String chat = '/app/chat';

  static const String groups = '/app/groups';

  /// Main navigation branch: Profile
  static const String profile = '/app/profile';

  /// Profile editing screen (basic info)
  static const String profileEdit = '/app/profile/edit';

  /// Profile details screen (progressive info)
  static const String profileDetails = '/app/profile/details';
  static const String personality = '/app/profile/personality';

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

enum EventDetailsOrigin { home, direct }
