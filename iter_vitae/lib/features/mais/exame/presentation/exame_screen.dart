import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../application/exame_controller.dart';

/// Tela do Exame de Consciência completo.
///
/// Cinco blocos em sequência:
///   1. Agradecimento
///   2. Presença de Deus
///   3. Luzes recebidas (fidelidade — puxado automaticamente)
///   4. Quedas
///   5. Propósito de amanhã
///
/// Diferente do [ReflectionInput] da tela Hoje, que é só texto livre rápido.
class ExameScreen extends ConsumerStatefulWidget {
  const ExameScreen({super.key});

  @override
  ConsumerState<ExameScreen> createState() => _ExameScreenState();
}

class _ExameScreenState extends ConsumerState<ExameScreen> {
  final _agradecimentoCtrl = TextEditingController();
  final _presencaCtrl = TextEditingController();
  final _luzesCtrl = TextEditingController();
  final _quedasCtrl = TextEditingController();
  final _propositoCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _agradecimentoCtrl.dispose();
    _presencaCtrl.dispose();
    _luzesCtrl.dispose();
    _quedasCtrl.dispose();
    _propositoCtrl.dispose();
    super.dispose();
  }

  void _initFromState(ExameState s) {
    if (_initialized) return;
    _agradecimentoCtrl.text = s.agradecimento;
    _presencaCtrl.text = s.presencaDeDeus;
    _luzesCtrl.text = s.luzes;
    _quedasCtrl.text = s.quedas;
    _propositoCtrl.text = s.proposito;
    _initialized = true;
  }

  ExameState _currentFields(ExameState base) {
    return base.copyWith(
      agradecimento: _agradecimentoCtrl.text,
      presencaDeDeus: _presencaCtrl.text,
      luzes: _luzesCtrl.text,
      quedas: _quedasCtrl.text,
      proposito: _propositoCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exame de consciência'),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar o exame.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) {
          _initFromState(state);
          return _ExameForm(
            agradecimentoCtrl: _agradecimentoCtrl,
            presencaCtrl: _presencaCtrl,
            luzesCtrl: _luzesCtrl,
            quedasCtrl: _quedasCtrl,
            propositoCtrl: _propositoCtrl,
            isSaved: state.isSaved,
            isSaving: state.isSaving,
            onSave: () {
              ref
                  .read(exameControllerProvider.notifier)
                  .save(_currentFields(state));
            },
          );
        },
      ),
    );
  }
}

// ── Formulário ────────────────────────────────────────────────────────────────

class _ExameForm extends StatelessWidget {
  const _ExameForm({
    required this.agradecimentoCtrl,
    required this.presencaCtrl,
    required this.luzesCtrl,
    required this.quedasCtrl,
    required this.propositoCtrl,
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController agradecimentoCtrl;
  final TextEditingController presencaCtrl;
  final TextEditingController luzesCtrl;
  final TextEditingController quedasCtrl;
  final TextEditingController propositoCtrl;
  final bool isSaved;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (isSaved)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Exame salvo hoje.',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        _ExameBlock(
          number: '1',
          title: 'Agradecimento',
          hint: 'Que graças recebi hoje?',
          controller: agradecimentoCtrl,
        ),
        const SizedBox(height: 20),

        _ExameBlock(
          number: '2',
          title: 'Presença de Deus',
          hint: 'Como Deus esteve presente no meu dia?',
          controller: presencaCtrl,
        ),
        const SizedBox(height: 20),

        _ExameBlock(
          number: '3',
          title: 'Fidelidade — luzes recebidas',
          hint: 'Que luzes ou consolações recebi nas práticas contemplativas?',
          controller: luzesCtrl,
        ),
        const SizedBox(height: 20),

        _ExameBlock(
          number: '4',
          title: 'Quedas',
          hint: 'O que foi difícil? Que falhas reconheço?',
          controller: quedasCtrl,
        ),
        const SizedBox(height: 20),

        _ExameBlock(
          number: '5',
          title: 'Propósito de amanhã',
          hint: 'Que resolução concreta levo para amanhã?',
          controller: propositoCtrl,
        ),
        const SizedBox(height: 28),

        FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar exame'),
        ),
      ],
    );
  }
}

// ── Bloco individual ──────────────────────────────────────────────────────────

class _ExameBlock extends StatelessWidget {
  const _ExameBlock({
    required this.number,
    required this.title,
    required this.hint,
    required this.controller,
  });

  final String number;
  final String title;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
