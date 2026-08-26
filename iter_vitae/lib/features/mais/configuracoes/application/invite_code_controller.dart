import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';

/// Estado do gerador de código de convite.
class InviteCodeState {
  const InviteCodeState({
    this.codigo,
    this.isGenerating = false,
    this.erro,
  });

  final String? codigo;
  final bool isGenerating;
  final String? erro;
}

/// Gera um código de 6 dígitos alfanumérico em /invite_codes/{codigo}
/// com validade de 24 horas.
class InviteCodeController extends AsyncNotifier<InviteCodeState> {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLen = 6;

  @override
  Future<InviteCodeState> build() async => const InviteCodeState();

  Future<void> gerarCodigo() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncData(InviteCodeState(isGenerating: true));

    try {
      final codigo = _generate();
      final db = FirebaseFirestore.instance;

      await db.collection('invite_codes').doc(codigo).set({
        'directeeUid': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'expiraEm': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'usado': false,
      });

      state = AsyncData(InviteCodeState(codigo: codigo));
    } catch (_) {
      state = const AsyncData(
        InviteCodeState(erro: 'Erro ao gerar código. Tente novamente.'),
      );
    }
  }

  String _generate() {
    final rng = Random.secure();
    return List.generate(_codeLen, (_) => _chars[rng.nextInt(_chars.length)])
        .join();
  }
}

final inviteCodeControllerProvider =
    AsyncNotifierProvider<InviteCodeController, InviteCodeState>(
  InviteCodeController.new,
);
