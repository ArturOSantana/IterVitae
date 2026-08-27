import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/struggle.dart';
import '../../../providers.dart';
import '../../hoje/application/hoje_controller.dart';
import '../../mais/lutas/application/lutas_controller.dart';

/// Serviço de domínio para criação e substituição de lutas ativas.
///
/// Centraliza a regra de foco único (uma luta ativa por vez), o diálogo de
/// confirmação de substituição e a persistência — evitando duplicação entre
/// [NewStruggleScreen] e [RegisterDirectionScreen].
class StruggleService {
  const StruggleService(this._ref);

  final WidgetRef _ref;

  /// Cria uma nova [Struggle] ativa.
  ///
  /// - Se já houver uma luta ativa, exibe o diálogo de confirmação no
  ///   [context] antes de encerrar a atual.
  /// - Retorna `true` se a luta foi criada com sucesso, `false` se o usuário
  ///   cancelou ou o contexto foi desmontado.
  ///
  /// [titulo] — descrição da nova luta.
  /// [origemDirecaoId] — id da [SpiritualDirection] de origem, ou null quando
  ///   criada por iniciativa própria.
  Future<bool> criarLuta(
    BuildContext context, {
    required String titulo,
    String? origemDirecaoId,
  }) async {
    final repo = _ref.read(struggleRepositoryProvider);
    final ativa = await repo.getActive();

    if (ativa != null) {
      if (!context.mounted) return false;
      final confirmar = await _mostrarDialogoSubstituicao(context, ativa);
      if (!confirmar) return false;

      await repo.save(
        ativa.copyWith(
          status: StruggleStatus.encerrada,
          endDate: DateTime.now(),
        ),
      );
    }

    final now = DateTime.now();
    final nova = Struggle(
      id: 'struggle_${now.millisecondsSinceEpoch}',
      title: titulo.trim(),
      status: StruggleStatus.ativa,
      startDate: now,
      origemDirecaoId: origemDirecaoId,
    );
    await repo.save(nova);

    _ref.invalidate(hojeControllerProvider);
    _ref.invalidate(lutasControllerProvider);
    return true;
  }

  /// Mostra o diálogo "Você já tem uma luta ativa: '…'. Encerrar e começar?"
  /// Retorna `true` se o usuário confirmar.
  Future<bool> _mostrarDialogoSubstituicao(
    BuildContext context,
    Struggle lutaAtual,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SubstituicaoDialog(lutaAtual: lutaAtual),
    );
    return result == true;
  }
}

// ── Diálogo de confirmação ────────────────────────────────────────────────────

class _SubstituicaoDialog extends StatelessWidget {
  const _SubstituicaoDialog({required this.lutaAtual});

  final Struggle lutaAtual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Luta ativa em andamento',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Você já tem uma luta ativa: '),
            TextSpan(
              text: '"${lutaAtual.title}"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: '. Encerrar essa e começar a nova?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB23A2E), // AppColors.rubric
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Encerrar e começar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
