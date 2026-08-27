import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/mais/configuracoes/application/aceitar_codigo_controller.dart';

/// Tela para o diretor espiritual inserir o código do dirigido e completar o vínculo.
class InserirCodigoDirigidoScreen extends ConsumerStatefulWidget {
  const InserirCodigoDirigidoScreen({super.key});

  @override
  ConsumerState<InserirCodigoDirigidoScreen> createState() =>
      _InserirCodigoDirigidoScreenState();
}

class _InserirCodigoDirigidoScreenState
    extends ConsumerState<InserirCodigoDirigidoScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(aceitarCodigoControllerProvider);
    final state = stateAsync.valueOrNull ?? const AceitarCodigoState();

    // Volta automaticamente após vínculo bem-sucedido
    if (state.vinculado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirigido vinculado com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular dirigido'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              Text(
                'Digite o código do seu dirigido.',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'O dirigido deve gerar um código em Configurações → '
                '"Vincular ao meu diretor". O código tem validade de 24 horas.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 40),

              // Campo de entrada do código
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                  color: AppColors.textPrimary,
                ),
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: GoogleFonts.fraunces(
                    fontSize: 32,
                    letterSpacing: 10,
                    color: AppColors.textMuted,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.rubric, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (_) {
                  // Limpa erro ao digitar
                  if (state.erro != null) {
                    ref
                        .read(aceitarCodigoControllerProvider.notifier)
                        .aceitar('');
                  }
                },
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 8),

              // Mensagem de erro
              if (state.erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.erro!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rubric,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: state.isLoading ? null : _submit,
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

  void _submit() {
    final code = _controller.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o código completo de 6 caracteres.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(aceitarCodigoControllerProvider.notifier).aceitar(code);
  }
}
