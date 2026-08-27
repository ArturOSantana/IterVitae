import '../entities/user_profile.dart';

/// Interface do repositório de perfil do usuário.
abstract interface class UserProfileRepository {
  /// Retorna o perfil atual do usuário, ou null se nunca foi salvo.
  Future<UserProfile?> get();

  /// Salva (insere ou substitui) o perfil do usuário.
  Future<void> save(UserProfile profile);
}
