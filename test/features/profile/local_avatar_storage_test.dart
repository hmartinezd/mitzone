import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/data/local_avatar_storage.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late LocalAvatarStorage storage;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'mitzone_avatar_storage_',
    );
    storage = LocalAvatarStorage(
      supportDirectoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('deletes only files within the requested managed identity', () async {
    final ownDirectory = Directory(
      p.join(temporaryDirectory.path, 'profile_avatars', 'identity-a'),
    );
    final otherDirectory = Directory(
      p.join(temporaryDirectory.path, 'profile_avatars', 'identity-b'),
    );
    await ownDirectory.create(recursive: true);
    await otherDirectory.create(recursive: true);
    final ownAvatar = await File(
      p.join(ownDirectory.path, 'avatar.png'),
    ).writeAsString('own');
    final otherAvatar = await File(
      p.join(otherDirectory.path, 'avatar.png'),
    ).writeAsString('other');
    final externalFile = await File(
      p.join(temporaryDirectory.path, 'external.png'),
    ).writeAsString('external');

    await storage.deleteAvatar(
      identityId: 'identity-a',
      avatarPath: otherAvatar.path,
    );
    await storage.deleteAvatar(
      identityId: 'identity-a',
      avatarPath: externalFile.path,
    );

    expect(await otherAvatar.exists(), isTrue);
    expect(await externalFile.exists(), isTrue);

    await storage.deleteAvatar(
      identityId: 'identity-a',
      avatarPath: ownAvatar.path,
    );
    expect(await ownAvatar.exists(), isFalse);
  });

  test('path traversal identity cannot delete an external file', () async {
    final externalFile = await File(
      p.join(temporaryDirectory.path, 'external.png'),
    ).writeAsString('external');

    await storage.deleteAvatar(
      identityId: '../../outside',
      avatarPath: externalFile.path,
    );

    expect(await externalFile.exists(), isTrue);
  });
}
