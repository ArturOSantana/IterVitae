import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Implementação in-memory do [UserProfileRepository] (usada antes do login).
class InMemoryUserProfileRepository implements UserProfileRepository {
  UserProfile? _profile;

  @override
  Future<UserProfile?> get() async => _profile;

  @override
  Future<void> save(UserProfile profile) async => _profile = profile;
}
