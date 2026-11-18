class PlacePhoto {
  const PlacePhoto({
    required this.name,
    required this.expiresAt,
    required this.signature,
    required this.authors,
    this.googleMapsUri,
  });

  final String name;
  final int expiresAt;
  final String signature;
  final List<PlacePhotoAuthor> authors;
  final Uri? googleMapsUri;

  static PlacePhoto? fromJson(Object? value) {
    if (value is! Map) return null;
    final name = value['name'];
    final expiresAt = value['expiresAt'];
    final signature = value['signature'];
    if (name is! String || expiresAt is! int || signature is! String) {
      return null;
    }
    final authors = value['authors'];
    return PlacePhoto(
      name: name,
      expiresAt: expiresAt,
      signature: signature,
      googleMapsUri: _httpsUri(value['googleMapsUri']),
      authors: [
        if (authors is List)
          for (final author in authors)
            if (author is Map && author['displayName'] is String)
              PlacePhotoAuthor(
                author['displayName'] as String,
                _httpsUri(author['uri']),
                _httpsUri(author['photoUri']),
              ),
      ],
    );
  }

  static Uri? _httpsUri(Object? value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}

class PlacePhotoAuthor {
  const PlacePhotoAuthor(this.displayName, this.profileUri, this.avatarUri);

  final String displayName;
  final Uri? profileUri;
  final Uri? avatarUri;
}
