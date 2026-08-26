import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iter_vitae/domain/entities/app_user.dart';
import 'package:iter_vitae/providers.dart';

/// Estado da autenticação.
sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Controller de autenticação — observa o stream do [AuthRepository].
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.userStream.first;
    if (user != null) return AuthAuthenticated(user);
    return const AuthUnauthenticated();
  }

  /// Faz login com email e senha. Retorna null em sucesso, mensagem de erro
  /// em falha.
  Future<String?> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user =
          await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      state = AsyncData(AuthAuthenticated(user));
      return null;
    } catch (e) {
      state = const AsyncData(AuthUnauthenticated());
      return _friendlyError(e);
    }
  }

  /// Faz login com Google.
  Future<String?> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = AsyncData(AuthAuthenticated(user));
      return null;
    } catch (e) {
      state = const AsyncData(AuthUnauthenticated());
      return _friendlyError(e);
    }
  }

  /// Cria conta com email e senha.
  Future<String?> createAccount(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .createAccountWithEmail(email, password);
      state = AsyncData(AuthAuthenticated(user));
      return null;
    } catch (e) {
      state = const AsyncData(AuthUnauthenticated());
      return _friendlyError(e);
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(AuthUnauthenticated());
  }

  String _friendlyError(Object e) {
    // Não expõe stack trace nem mensagens internas ao usuário
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('user-not-found')) return 'Conta não encontrada.';
    if (msg.contains('email-already-in-use')) return 'Email já cadastrado.';
    if (msg.contains('weak-password')) return 'Senha muito fraca.';
    if (msg.contains('cancelado')) return 'Login cancelado.';
    if (msg.contains('network')) return 'Sem conexão com a internet.';
    return 'Ocorreu um erro. Tente novamente.';
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
