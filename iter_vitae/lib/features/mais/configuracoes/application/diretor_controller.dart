import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers.dart';

/// Estado do controller de informações do diretor.
class DiretorState {
  const DiretorState({
    this.nome,
    this.contato,
    this.paroquia,
    this.directionId,
    this.isSaving = false,
  });

  final String? nome;
  final String? contato;
  final String? paroquia;

  /// ID da direção ativa onde os dados são persistidos.
  final String? directionId;

  final bool isSaving;

  DiretorState copyWith({
    String? nome,
    String? contato,
    String? paroquia,
    String? directionId,
    bool? isSaving,
  }) {
    return DiretorState(
      nome: nome ?? this.nome,
      contato: contato ?? this.contato,
      paroquia: paroquia ?? this.paroquia,
      directionId: directionId ?? this.directionId,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Gerencia os campos de contato do diretor espiritual.
///
/// Os dados são guardados na direção ativa (getOrCreateNext) e propagados
/// para todas as direções subsequentes via [save].
class DiretorController extends AsyncNotifier<DiretorState> {
  @override
  Future<DiretorState> build() async {
    final repo = ref.read(directionRepositoryProvider);
    // Usa getNext() (somente leitura) para não criar documento no Firestore
    // durante o build. A criação ocorre apenas no save(), quando o usuário
    // efetivamente interage.
    final direction = await repo.getNext();
    return DiretorState(
      nome: direction?.directorName,
      contato: direction?.diretorContato,
      paroquia: direction?.diretorParoquia,
      directionId: direction?.id,
    );
  }

  /// Persiste as alterações nos campos do diretor na direção ativa.
  /// Cria a direção no Firestore se ainda não existir.
  Future<void> save({
    required String nome,
    required String contato,
    required String paroquia,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));

    try {
      final repo = ref.read(directionRepositoryProvider);
      final direction = await repo.getOrCreateNext();

      final updated = direction.copyWith(
        directorName: nome.trim().isEmpty ? null : nome.trim(),
        diretorContato: contato.trim().isEmpty ? null : contato.trim(),
        diretorParoquia: paroquia.trim().isEmpty ? null : paroquia.trim(),
      );
      await repo.save(updated);

      state = AsyncData(DiretorState(
        nome: updated.directorName,
        contato: updated.diretorContato,
        paroquia: updated.diretorParoquia,
        directionId: updated.id,
        isSaving: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isSaving: false));
    }
  }
}

final diretorControllerProvider =
    AsyncNotifierProvider<DiretorController, DiretorState>(
  DiretorController.new,
);
