import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';

/// Estado do resgate de código do diretor.
class ResgatarCodigoDiretorState {
  const ResgatarCodigoDiretorState({
    this.isLoading = false,
    this.vinculado = false,
    this.erro,
  });

  final bool isLoading;
  final bool vinculado;
  final String? erro;
}

/// O dirigido digita o código gerado pelo diretor.
///
/// Fluxo:
/// 1. Busca /director_invite_codes/{codigo}
/// 2. Valida: existe, não usado, não expirado
/// 3. Grava users/{uid}.directorUid = directorUid do código
/// 4. Marca o código como usado
class ResgatarCodigoDiretorController
    extends AsyncNotifier<ResgatarCodigoDiretorState> {
  @override
  Future<ResgatarCodigoDiretorState> build() async =>
      const ResgatarCodigoDiretorState();

  Future<void> resgatar(String codigoRaw) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final codigo = codigoRaw.trim().toUpperCase();
    if (codigo.isEmpty) {
      state = const AsyncData(
        ResgatarCodigoDiretorState(erro: 'Digite o código.'),
      );
      return;
    }

    state = const AsyncData(ResgatarCodigoDiretorState(isLoading: true));

    try {
      final db = FirebaseFirestore.instance;
      final docRef = db.collection('invite_codes').doc(codigo);
      final snap = await docRef.get();

      if (!snap.exists) {
        state = const AsyncData(
          ResgatarCodigoDiretorState(erro: 'Código inválido ou não encontrado.'),
        );
        return;
      }

      final data = snap.data()!;
      final usado = data['usado'] as bool? ?? false;
      final expiraEm = (data['expiraEm'] as Timestamp).toDate();
      // Campo-chave conforme padrão do app diretor: diretorUid (sem acento)
      final directorUid = data['diretorUid'] as String?;

      if (usado) {
        state = const AsyncData(
          ResgatarCodigoDiretorState(erro: 'Este código já foi utilizado.'),
        );
        return;
      }

      if (DateTime.now().isAfter(expiraEm)) {
        state = const AsyncData(
          ResgatarCodigoDiretorState(erro: 'Este código já expirou.'),
        );
        return;
      }

      if (directorUid == null || directorUid.isEmpty) {
        state = const AsyncData(
          ResgatarCodigoDiretorState(erro: 'Código inválido.'),
        );
        return;
      }

      // Grava o vínculo e marca o código como usado atomicamente
      final batch = db.batch();
      batch.update(
        db.collection('users').doc(user.uid),
        {'directorUid': directorUid},
      );
      batch.update(docRef, {'usado': true});
      await batch.commit();

      state = const AsyncData(ResgatarCodigoDiretorState(vinculado: true));
    } catch (e, st) {
      dev.log(
        'ResgatarCodigoDiretorController.resgatar error: $e',
        stackTrace: st,
      );
      state = const AsyncData(
        ResgatarCodigoDiretorState(erro: 'Erro ao resgatar código. Tente novamente.'),
      );
    }
  }
}

final resgatarCodigoDiretorControllerProvider =
    AsyncNotifierProvider<ResgatarCodigoDiretorController,
        ResgatarCodigoDiretorState>(
  ResgatarCodigoDiretorController.new,
);
