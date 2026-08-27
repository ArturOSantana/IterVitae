import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/mais/configuracoes/application/resgatar_codigo_diretor_controller.dart';

/// Tela onde o dirigido digita o código gerado pelo diretor espiritual.
class ResgatarCodigoDiretorScreen extends ConsumerStatefulWidget {
  const ResgatarCodigoDiretorScreen({super.key});

  @override
  ConsumerState<ResgatarCodigoDiretorScreen> createState() =>
      _ResgatarCodigoDiretorScreenState();
}

class _ResgatarCodigoDiretorScreenState
    extends ConsumerState<ResgatarCodigoDiretorScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(resgatarCodigoDiretorControllerProvider);
    final state =
        stateAsync.valueOrNull ?? const ResgatarCodigoDiretorState();

    // Navega para trás com feedback após vínculo bem-sucedido
    ref.listen(resgatarCodigoDiretorControllerProvider, (_, next) {
      final s = next.valueOrNull;
      if (s != null && s.vinculado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vínculo realizado com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inserir código do diretor'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              Text(
                'Seu diretor enviou um código?',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Digite o código de 6 caracteres gerado pelo seu diretor espiritual '
                'para completar o vínculo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _ctrl,
                enabled: !state.isLoading,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: GoogleFonts.fraunces(
                    fontSize: 32,
                    letterSpacing: 10,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.rubric, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                ),
                onChanged: (_) {
                  // Limpa o erro ao editar
                  if (stateAsync.valueOrNull?.erro != null) {
                    ref
                        .read(resgatarCodigoDiretorControllerProvider.notifier)
                        .build();
                  }
                },
              ),
              if (state.erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.erro!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rubric,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: state.isLoading
                      ? null
                      : () => ref
                          .read(
                              resgatarCodigoDiretorControllerProvider.notifier)
                          .resgatar(_ctrl.text),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirmar vínculo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
