import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/user_profile.dart';
import 'avatar_picker.dart';
import 'avatar_storage.dart';
import 'local_avatar_storage.dart';
import 'local_profile_repository.dart';
import 'profile_repository.dart';
import '../../../core/auth/auth_providers.dart';
import 'supabase_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  final auth = ref.watch(authRepositoryProvider);
  return auth == null ? LocalProfileRepository(storage) : SupabaseProfileRepository(Supabase.instance.client);
});

/// Provider for the [AvatarStorage].
final avatarStorageProvider = Provider<AvatarStorage>((ref) {
  return LocalAvatarStorage();
});

/// Provider for the [AvatarPicker].
final avatarPickerProvider = Provider<AvatarPicker>((ref) {
  return ImagePickerAvatarPicker(ImagePicker());
});

/// Reusable provider for the profile associated with the current local-development identity.
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (ref.watch(productionModeProvider) && session == null) return null;
  final mockIdentity = ref.watch(mockIdentityRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final user = session == null ? mockIdentity.currentUser : UserProfile(id: session.user.id, displayName: '');
  if (session != null) return profileRepository.getProfile(session.user.id);
  return await profileRepository.getProfile(user.id) ?? user;
});
