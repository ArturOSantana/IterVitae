import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/mais/configuracoes/application/director_invite_code_controller.dart';

/// Tela para o diretor gerar um código que o dirigido pode inserir.
///
/// Aberta a partir de Configurações → "Gerar código para dirigido".
class GerarCodigoDirigidoScreen extends ConsumerWidget {
  const GerarCodigoDirigidoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(directorInviteCodeControllerProvider);
    final state =
        stateAsync.valueOrNull ?? const DirectorInviteCodeState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar código para dirigido'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              Text(
                'Gere um código e envie ao seu dirigido.',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'O código expira em 24 horas e só pode ser usado uma vez. '
                'O dirigido deve digitá-lo no app dele para completar o vínculo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 40),

              if (state.codigo != null) ...[
                _CodigoDisplay(codigo: state.codigo!),
                const SizedBox(height: 24),
                Text(
                  'Envie este código ao seu dirigido. '
                  'Ele deve digitá-lo no app para completar o vínculo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rubric,
                    side: const BorderSide(color: AppColors.rubric),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => ref
                      .read(directorInviteCodeControllerProvider.notifier)
                      .gerarCodigo(),
                  child: const Text('Gerar novo código'),
                ),
              ] else ...[
                if (state.erro != null) ...[
                  Text(
                    state.erro!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.rubric,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: state.isGenerating
                        ? null
                        : () => ref
                            .read(
                                directorInviteCodeControllerProvider.notifier)
                            .gerarCodigo(),
                    child: state.isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Gerar código de vínculo'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Exibe o código em destaque com botão de copiar.
class _CodigoDisplay extends StatelessWidget {
  const _CodigoDisplay({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubric, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            codigo,
            style: GoogleFonts.fraunces(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
              color: AppColors.rubric,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar código'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: codigo));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código copiado.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
