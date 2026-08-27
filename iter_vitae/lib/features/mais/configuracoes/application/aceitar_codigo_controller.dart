import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';

/// Estado do controller de aceitação de código do dirigido.
class AceitarCodigoState {
  const AceitarCodigoState({
    this.isLoading = false,
    this.vinculado = false,
    this.erro,
  });

  final bool isLoading;
  final bool vinculado;
  final String? erro;
}

/// O diretor digita o código gerado pelo dirigido.
///
/// Fluxo:
/// 1. Lê /invite_codes/{code} — valida existência, expiração e se não foi usado.
/// 2. Marca o código como usado (allow update nas regras).
/// 3. Cria /directors/{directorUid}/directees/{directeeUid} com dados básicos.
/// 4. Grava directorUid no documento do dirigido /users/{directeeUid}.
class AceitarCodigoController extends AsyncNotifier<AceitarCodigoState> {
  @override
  Future<AceitarCodigoState> build() async => const AceitarCodigoState();

  Future<void> aceitar(String codigo) async {
    final code = codigo.trim().toUpperCase();
    if (code.isEmpty) return;

    final diretor = ref.read(currentUserProvider).valueOrNull;
    if (diretor == null) return;

    state = const AsyncData(AceitarCodigoState(isLoading: true));

    final db = FirebaseFirestore.instance;

    try {
      // 1. Busca o documento do código
      final codeDoc = await db.collection('invite_codes').doc(code).get();

      if (!codeDoc.exists) {
        state = const AsyncData(
          AceitarCodigoState(erro: 'Código não encontrado. Verifique e tente novamente.'),
        );
        return;
      }

      final data = codeDoc.data()!;
      final usado = data['usado'] as bool? ?? true;
      final expiraEm = (data['expiraEm'] as Timestamp?)?.toDate();
      final directeeUid = data['directeeUid'] as String?;

      if (usado) {
        state = const AsyncData(
          AceitarCodigoState(erro: 'Este código já foi utilizado.'),
        );
        return;
      }

      if (expiraEm != null && DateTime.now().isAfter(expiraEm)) {
        state = const AsyncData(
          AceitarCodigoState(erro: 'Este código expirou. Peça ao dirigido que gere um novo.'),
        );
        return;
      }

      if (directeeUid == null || directeeUid.isEmpty) {
        state = const AsyncData(
          AceitarCodigoState(erro: 'Código inválido. Tente novamente.'),
        );
        return;
      }

      // 2. Executa as três escritas em batch
      final batch = db.batch();

      // Marca código como usado
      batch.update(db.collection('invite_codes').doc(code), {'usado': true});

      // Cria registro do dirigido na coleção do diretor
      batch.set(
        db
            .collection('directors')
            .doc(diretor.uid)
            .collection('directees')
            .doc(directeeUid),
        {
          'directeeUid': directeeUid,
          'vinculadoEm': FieldValue.serverTimestamp(),
        },
      );

      // Grava directorUid no documento do dirigido
      batch.set(
        db.collection('users').doc(directeeUid),
        {'directorUid': diretor.uid},
        SetOptions(merge: true),
      );

      await batch.commit();

      state = const AsyncData(AceitarCodigoState(vinculado: true));
    } catch (_) {
      state = const AsyncData(
        AceitarCodigoState(erro: 'Erro ao vincular. Tente novamente.'),
      );
    }
  }
}

final aceitarCodigoControllerProvider =
    AsyncNotifierProvider<AceitarCodigoController, AceitarCodigoState>(
  AceitarCodigoController.new,
);
