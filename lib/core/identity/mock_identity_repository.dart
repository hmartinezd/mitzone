import 'package:flutter/foundation.dart';
import '../../features/profile/domain/user_profile.dart';
import 'app_identity.dart';
import 'identity_gateway.dart';

/// Local identity source used while authentication and backend services are deferred.
abstract interface class MockIdentityRepository {
  UserProfile get currentUser;
  List<UserProfile> get users;
  Future<void> setCurrentUser(String id);
}

class MockIdentityGateway implements IdentityGateway {
  MockIdentityGateway(this._repository);
  final MockIdentityRepository _repository;

  AppIdentity _identity() => AppIdentity(
    id: _repository.currentUser.id,
    type: AppIdentityType.localDevelopment,
  );

  @override
  Future<AppIdentity> ensureIdentity() async => _identity();

  @override
  Future<AppIdentity?> getExistingIdentity() async => _identity();
}

class InMemoryMockIdentityRepository extends ChangeNotifier
    implements MockIdentityRepository {
  InMemoryMockIdentityRepository({String initialUserId = MockUsers.joseId})
    : _currentUserId = initialUserId;

  static const String joseId = MockUsers.joseId;
  String _currentUserId;

  @override
  List<UserProfile> get users => MockUsers.all;

  @override
  UserProfile get currentUser => users.firstWhere(
    (user) => user.id == _currentUserId,
    orElse: () => users.first,
  );

  @override
  Future<void> setCurrentUser(String id) async {
    if (!users.any((user) => user.id == id)) {
      throw ArgumentError.value(id, 'id', 'Unknown mock user');
    }
    if (_currentUserId == id) return;
    _currentUserId = id;
    notifyListeners();
  }
}

/// Stable, centralized development identities.
abstract final class MockUsers {
  static const joseId = 'mock-user-jose-v1';
  static const sofiaId = 'mock-user-sofia-v1';
  static const danielId = 'mock-user-daniel-v1';
  static const emmaId = 'mock-user-emma-v1';

  static final all = <UserProfile>[
    const UserProfile(
      id: joseId,
      displayName: 'Jose',
      bio: 'Always up for a good game and a great meal.',
      city: 'New York',
      languages: ['English', 'Spanish'],
      interests: ['Soccer', 'Tennis', 'Music', 'Food'],
      connectionGoal: ConnectionGoal.both,
    ),
    const UserProfile(
      id: sofiaId,
      displayName: 'Sofia',
      bio: 'Exploring the city one playlist and trip at a time.',
      city: 'New York',
      languages: ['English', 'Spanish'],
      interests: ['Tennis', 'Music', 'Travel', 'Food'],
      connectionGoal: ConnectionGoal.social,
    ),
    const UserProfile(
      id: danielId,
      displayName: 'Daniel',
      bio: 'Building things, staying active, and meeting curious people.',
      city: 'New York',
      languages: ['English'],
      interests: ['Soccer', 'Technology', 'Business', 'Fitness'],
      connectionGoal: ConnectionGoal.professional,
    ),
    const UserProfile(
      id: emmaId,
      displayName: 'Emma',
      bio: 'Creative spirit who loves sharing local discoveries.',
      city: 'New York',
      languages: ['English', 'French'],
      interests: ['Music', 'Art', 'Food', 'Travel'],
      connectionGoal: ConnectionGoal.social,
    ),
  ];
}
