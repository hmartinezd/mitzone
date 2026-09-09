import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/identity/identity_providers.dart';
import '../../features/onboarding/data/onboarding_providers.dart';
import '../../features/profile/data/profile_providers.dart';
import 'app_entry_resolver.dart';

/// The single authoritative entry-policy dependency graph used by startup,
/// onboarding completion, and authenticated-route redirects.
final appEntryResolverProvider = Provider<AppEntryResolver>((ref) {
  return AppEntryResolver(
    onboardingStatusStore: ref.read(onboardingStatusStoreProvider),
    identityGateway: ref.read(identityGatewayProvider),
    profileRepository: ref.read(profileRepositoryProvider),
    authRepository: ref.read(authRepositoryProvider),
  );
});
