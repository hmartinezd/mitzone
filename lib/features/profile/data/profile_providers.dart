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
import '../../../core/identity/current_user_provider.dart';

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
  final id = await ref.watch(currentUserIdProvider.future);
  final session = await ref.watch(authSessionProvider.future);
  final mockIdentity = ref.watch(mockIdentityRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  if (session != null) return profileRepository.getProfile(id);
  final user = mockIdentity.currentUser;
  return await profileRepository.getProfile(user.id) ?? user;
});
