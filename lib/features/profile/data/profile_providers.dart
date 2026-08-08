import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/storage/storage_providers.dart';
import 'avatar_picker.dart';
import 'avatar_storage.dart';
import 'local_avatar_storage.dart';
import 'local_profile_repository.dart';
import 'profile_repository.dart';

/// Provider for the [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return LocalProfileRepository(storage);
});

/// Provider for the [AvatarStorage].
final avatarStorageProvider = Provider<AvatarStorage>((ref) {
  return LocalAvatarStorage();
});

/// Provider for the [AvatarPicker].
final avatarPickerProvider = Provider<AvatarPicker>((ref) {
  return ImagePickerAvatarPicker(ImagePicker());
});
