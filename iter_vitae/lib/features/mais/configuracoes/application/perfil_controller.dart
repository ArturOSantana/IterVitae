import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/user_profile.dart';
import '../../../../providers.dart';

/// Estado do controller de perfil do usuário.
class PerfilState {
  const PerfilState({
    this.nome,
    this.telefone,
    this.paroquia,
    this.isSaving = false,
  });

  final String? nome;
  final String? telefone;
  final String? paroquia;
  final bool isSaving;

  PerfilState copyWith({
    String? nome,
    String? telefone,
    String? paroquia,
    bool? isSaving,
  }) {
    return PerfilState(
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      paroquia: paroquia ?? this.paroquia,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Gerencia o perfil pessoal do usuário (nome, telefone, paróquia).
class PerfilController extends AsyncNotifier<PerfilState> {
  @override
  Future<PerfilState> build() async {
    final repo = ref.read(userProfileRepositoryProvider);
    final profile = await repo.get();
    return PerfilState(
      nome: profile?.nome,
      telefone: profile?.telefone,
      paroquia: profile?.paroquia,
    );
  }

  /// Persiste as alterações do perfil no Firestore.
  Future<void> save({
    required String nome,
    required String telefone,
    required String paroquia,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));

    try {
      final repo = ref.read(userProfileRepositoryProvider);
      final profile = UserProfile(
        nome: nome.trim().isEmpty ? null : nome.trim(),
        telefone: telefone.trim().isEmpty ? null : telefone.trim(),
        paroquia: paroquia.trim().isEmpty ? null : paroquia.trim(),
      );
      await repo.save(profile);

      state = AsyncData(PerfilState(
        nome: profile.nome,
        telefone: profile.telefone,
        paroquia: profile.paroquia,
        isSaving: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isSaving: false));
    }
  }
}

final perfilControllerProvider =
    AsyncNotifierProvider<PerfilController, PerfilState>(
  PerfilController.new,
);
