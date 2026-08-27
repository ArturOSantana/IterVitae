import 'dart:developer' as dev;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';
import 'diretor_controller.dart';

/// Estado do gerador de código de convite do diretor.
class DirectorInviteCodeState {
  const DirectorInviteCodeState({
    this.codigo,
    this.isGenerating = false,
    this.erro,
  });

  final String? codigo;
  final bool isGenerating;
  final String? erro;
}

/// O diretor gera um código de 6 dígitos em /director_invite_codes/{codigo}
/// com validade de 24 horas. O dirigido digita esse código para se vincular.
class DirectorInviteCodeController
    extends AsyncNotifier<DirectorInviteCodeState> {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLen = 6;

  @override
  Future<DirectorInviteCodeState> build() async =>
      const DirectorInviteCodeState();

  Future<void> gerarCodigo() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncData(DirectorInviteCodeState(isGenerating: true));

    try {
      final codigo = _generate();
      final db = FirebaseFirestore.instance;

      // Lê o perfil do diretor para incluir nome/telefone/paróquia no código.
      // Assim o dirigido recebe essas infos fixas ao resgatar.
      final diretorState =
          ref.read(diretorControllerProvider).valueOrNull;

      await db.collection('invite_codes').doc(codigo).set({
        'diretorUid': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'expiraEm': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'usado': false,
        if (diretorState?.nome?.isNotEmpty == true)
          'diretorNome': diretorState!.nome,
        if (diretorState?.contato?.isNotEmpty == true)
          'diretorTelefone': diretorState!.contato,
        if (diretorState?.paroquia?.isNotEmpty == true)
          'diretorParoquia': diretorState!.paroquia,
      });

      state = AsyncData(DirectorInviteCodeState(codigo: codigo));
    } catch (e, st) {
      dev.log(
        'DirectorInviteCodeController.gerarCodigo error: $e',
        stackTrace: st,
      );
      state = AsyncData(
        DirectorInviteCodeState(erro: 'Erro ao gerar código: $e'),
      );
    }
  }

  String _generate() {
    final rng = Random.secure();
    return List.generate(_codeLen, (_) => _chars[rng.nextInt(_chars.length)])
        .join();
  }
}

final directorInviteCodeControllerProvider =
    AsyncNotifierProvider<DirectorInviteCodeController,
        DirectorInviteCodeState>(
  DirectorInviteCodeController.new,
);
