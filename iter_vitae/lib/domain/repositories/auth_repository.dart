import '../entities/app_user.dart';

/// Interface do repositório de autenticação.
/// TODO: implementado por [FirebaseAuthRepository].
abstract interface class AuthRepository {
  /// Stream do usuário atual. Emite null quando deslogado.
  Stream<AppUser?> get userStream;

  /// Usuário atual (null se não autenticado).
  AppUser? get currentUser;

  /// Login com email e senha.
  Future<AppUser> signInWithEmail(String email, String password);

  /// Login com Google.
  Future<AppUser> signInWithGoogle();

  /// Cria conta com email e senha.
  Future<AppUser> createAccountWithEmail(String email, String password);

  /// Logout.
  Future<void> signOut();
}
