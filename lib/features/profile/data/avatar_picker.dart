import 'package:image_picker/image_picker.dart';

/// Represents a picked avatar image.
class PickedAvatar {
  const PickedAvatar({required this.path, required this.name});

  final String path;
  final String name;
}

/// Interface for picking profile images from the user's device.
abstract interface class AvatarPicker {
  /// Picks an image from the gallery.
  Future<PickedAvatar?> pickFromGallery();
}

/// Implementation of [AvatarPicker] using [ImagePicker].
class ImagePickerAvatarPicker implements AvatarPicker {
  ImagePickerAvatarPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<PickedAvatar?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (image == null) return null;

    return PickedAvatar(path: image.path, name: image.name);
  }
}
