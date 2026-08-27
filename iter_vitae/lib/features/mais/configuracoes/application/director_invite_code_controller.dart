import 'dart:developer' as dev;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';

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

      await db.collection('invite_codes').doc(codigo).set({
        'diretorUid': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'expiraEm': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'usado': false,
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
