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
/// 1. Busca /invite_codes/{codigo}
/// 2. Valida: existe, não usado, não expirado
/// 3. Grava users/{uid}.directorUid = directorUid do código
/// 4. Grava vínculo em /directors/{directorUid}/directees/{uid}
/// 5. Marca o código como usado
/// 6. Se o código contiver diretorNome/diretorTelefone/diretorParoquia,
///    preenche automaticamente a direção ativa do dirigido.
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

      // Campos opcionais que o app diretor pode ter incluído no código
      final diretorNome = data['nome'] as String?;
      final diretorTelefone = data['telefone'] as String?;
      final diretorParoquia = data['paroquia'] as String?;

      // Grava o vínculo atomicamente:
      // 1. directorUid no perfil do dirigido (para envio de relatórios, etc.)
      // 2. registro do vínculo em /directors/{directorUid}/directees/{uid}
      // 3. marca o código como usado (evita reutilização)
      final batch = db.batch();
      // set+merge: suporta tanto o caso em que users/{uid} já existe
      // quanto o caso em que o documento ainda não foi criado.
      batch.set(
        db.collection('users').doc(user.uid),
        {'directorUid': directorUid},
        SetOptions(merge: true),
      );
      batch.set(
        db
            .collection('directors')
            .doc(directorUid)
            .collection('directees')
            .doc(user.uid),
        {'vinculadoEm': FieldValue.serverTimestamp()},
      );
      batch.update(docRef, {'usado': true});
      await batch.commit();

      // Se o código contiver infos do diretor, preenche automaticamente
      // a direção ativa do dirigido para que fiquem fixas nas configurações.
      if (diretorNome != null && diretorNome.isNotEmpty) {
        try {
          final repo = ref.read(directionRepositoryProvider);
          final direction = await repo.getOrCreateNext();
          final updated = direction.copyWith(
            directorName: diretorNome,
            diretorContato:
                diretorTelefone?.isNotEmpty == true ? diretorTelefone : null,
            diretorParoquia:
                diretorParoquia?.isNotEmpty == true ? diretorParoquia : null,
          );
          await repo.save(updated);
        } catch (e, st) {
          dev.log(
            'ResgatarCodigoDiretorController: erro ao salvar infos do diretor: $e',
            stackTrace: st,
          );
          // Falha silenciosa — o vínculo já foi criado com sucesso
        }
      }

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
