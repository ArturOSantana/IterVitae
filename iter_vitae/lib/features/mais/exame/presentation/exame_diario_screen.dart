import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/practice_icons.dart';
import '../../../../domain/entities/exame_diario.dart';
import '../application/exame_diario_controller.dart';

/// Tela do Exame Diário de Consciência — estrutura inaciana dos Exercícios Espirituais.
///
/// Dois modos selecionados por toggle no topo:
///   - "Hoje" → formulário dos cinco passos do dia atual
///   - "Esta semana" → releitura textual dos registros da semana corrente
class ExameDiarioScreen extends ConsumerStatefulWidget {
  const ExameDiarioScreen({super.key});

  @override
  ConsumerState<ExameDiarioScreen> createState() => _ExameDiarioScreenState();
}

class _ExameDiarioScreenState extends ConsumerState<ExameDiarioScreen> {
  final _gratidaoCtrl = TextEditingController();
  final _revisaoCtrl = TextEditingController();
  final _arrependimentoCtrl = TextEditingController();
  final _propositoCtrl = TextEditingController();
  bool _initialized = false;
  bool _modoSemana = false;

  @override
  void dispose() {
    _gratidaoCtrl.dispose();
    _revisaoCtrl.dispose();
    _arrependimentoCtrl.dispose();
    _propositoCtrl.dispose();
    super.dispose();
  }

  void _initFromState(ExameDiarioState s) {
    if (_initialized) return;
    _gratidaoCtrl.text = s.gratidao;
    _revisaoCtrl.text = s.revisaoDia;
    _arrependimentoCtrl.text = s.arrependimento;
    _propositoCtrl.text = s.proposito;
    _initialized = true;
  }

  ExameDiarioState _coletarCampos(ExameDiarioState base) {
    return base.copyWith(
      gratidao: _gratidaoCtrl.text,
      revisaoDia: _revisaoCtrl.text,
      arrependimento: _arrependimentoCtrl.text,
      proposito: _propositoCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exameDiarioControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exame diário'),
        centerTitle: false,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              // ── Toggle Hoje / Esta semana ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _ModoToggle(
                  modoSemana: _modoSemana,
                  onChanged: (v) => setState(() => _modoSemana = v),
                ),
              ),

              // ── Conteúdo ────────────────────────────────────────────────────
              Expanded(
                child: _modoSemana
                    ? const _VisaoSemanal()
                    : async.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Center(
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
                          return _ExameDiarioForm(
                            gratidaoCtrl: _gratidaoCtrl,
                            revisaoCtrl: _revisaoCtrl,
                            arrependimentoCtrl: _arrependimentoCtrl,
                            propositoCtrl: _propositoCtrl,
                            praticasHoje: state.praticasHoje,
                            isSaved: state.isSaved,
                            isSaving: state.isSaving,
                            onSave: () {
                              ref
                                  .read(exameDiarioControllerProvider.notifier)
                                  .save(_coletarCampos(state));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle ────────────────────────────────────────────────────────────────────

class _ModoToggle extends StatelessWidget {
  const _ModoToggle({
    required this.modoSemana,
    required this.onChanged,
  });

  final bool modoSemana;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _ToggleTab(
            label: 'Hoje',
            selected: !modoSemana,
            onTap: () => onChanged(false),
            theme: theme,
          ),
          _ToggleTab(
            label: 'Esta semana',
            selected: modoSemana,
            onTap: () => onChanged(true),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.border : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Visão semanal ─────────────────────────────────────────────────────────────

class _VisaoSemanal extends ConsumerWidget {
  const _VisaoSemanal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exameDiarioSemanaProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar os registros da semana.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (semana) => _ListaSemanal(semana: semana),
    );
  }
}

class _ListaSemanal extends StatelessWidget {
  const _ListaSemanal({required this.semana});

  final List<ExameDiario?> semana;

  static const _nomesDias = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = startOfWeekFor(DateTime.now());
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final dia = start.add(Duration(days: i));
        final exame = semana[i];
        return _DiaBloco(
          nomeDia: _nomesDias[i],
          data: dia,
          exame: exame,
          theme: theme,
        );
      },
    );
  }
}

class _DiaBloco extends StatelessWidget {
  const _DiaBloco({
    required this.nomeDia,
    required this.data,
    required this.exame,
    required this.theme,
  });

  final String nomeDia;
  final DateTime data;
  final ExameDiario? exame;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dataFmt = DateFormat("d 'de' MMMM", 'pt_BR').format(data);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do dia
          Row(
            children: [
              Text(
                nomeDia,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dataFmt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          if (exame == null) ...[
            const SizedBox(height: 8),
            Text(
              'Sem registro nesse dia.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _CampoResumo(rotulo: 'Gratidão', texto: exame!.gratidao),
            _CampoResumo(rotulo: 'Revisão do dia', texto: exame!.revisaoDia),
            _CampoResumo(rotulo: 'Arrependimento', texto: exame!.arrependimento),
            _CampoResumo(rotulo: 'Propósito', texto: exame!.proposito),
          ],
        ],
      ),
    );
  }
}

class _CampoResumo extends StatelessWidget {
  const _CampoResumo({required this.rotulo, required this.texto});

  final String rotulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formulário (modo "Hoje") ───────────────────────────────────────────────────

class _ExameDiarioForm extends StatelessWidget {
  const _ExameDiarioForm({
    required this.gratidaoCtrl,
    required this.revisaoCtrl,
    required this.arrependimentoCtrl,
    required this.propositoCtrl,
    required this.praticasHoje,
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController gratidaoCtrl;
  final TextEditingController revisaoCtrl;
  final TextEditingController arrependimentoCtrl;
  final TextEditingController propositoCtrl;
  final List<PraticaResumo> praticasHoje;
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

        // ── 1. Gratidão ────────────────────────────────────────────────
        _ExameBloco(
          numero: '1',
          titulo: 'Gratidão',
          hint: 'Pelo que agradeço hoje?',
          controller: gratidaoCtrl,
        ),
        const SizedBox(height: 24),

        // ── 2. Pedido de luz (texto estático, sem campo) ───────────────
        _BlocoTextoEstatico(
          numero: '2',
          titulo: 'Pedido de luz',
          texto:
              'Peço ao Senhor que ilumine minha mente e meu coração, '
              'para que eu possa ver meu dia com os olhos de Deus — '
              'com verdade e misericórdia.',
        ),
        const SizedBox(height: 24),

        // ── 3. Revisão do dia ──────────────────────────────────────────
        _BlocoRevisaoDia(
          controller: revisaoCtrl,
          praticasHoje: praticasHoje,
        ),
        const SizedBox(height: 24),

        // ── 4. Arrependimento ──────────────────────────────────────────
        _ExameBloco(
          numero: '4',
          titulo: 'Arrependimento',
          hint: 'Onde falhei? Peço perdão por...',
          controller: arrependimentoCtrl,
        ),
        const SizedBox(height: 24),

        // ── 5. Propósito ───────────────────────────────────────────────
        _ExameBloco(
          numero: '5',
          titulo: 'Propósito para amanhã',
          hint: 'Meu propósito para amanhã',
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

// ── Bloco com campo de texto ──────────────────────────────────────────────────

class _ExameBloco extends StatelessWidget {
  const _ExameBloco({
    required this.numero,
    required this.titulo,
    required this.hint,
    required this.controller,
  });

  final String numero;
  final String titulo;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoBloco(numero: numero, titulo: titulo),
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

// ── Bloco estático (passo 2) ──────────────────────────────────────────────────

class _BlocoTextoEstatico extends StatelessWidget {
  const _BlocoTextoEstatico({
    required this.numero,
    required this.titulo,
    required this.texto,
  });

  final String numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoBloco(numero: numero, titulo: titulo),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            texto,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bloco revisão do dia (passo 3) ───────────────────────────────────────────

class _BlocoRevisaoDia extends StatelessWidget {
  const _BlocoRevisaoDia({
    required this.controller,
    required this.praticasHoje,
  });

  final TextEditingController controller;
  final List<PraticaResumo> praticasHoje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoBloco(numero: '3', titulo: 'Revisão do dia'),
        const SizedBox(height: 8),

        // Fidelidade automática das práticas
        if (praticasHoje.isNotEmpty) ...[
          Text(
            'Fidelidade de hoje',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          ...praticasHoje.map((p) => _PraticaResumoItem(pratica: p)),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: controller,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Como vivi este dia?',
          ),
        ),
      ],
    );
  }
}

class _PraticaResumoItem extends StatelessWidget {
  const _PraticaResumoItem({required this.pratica});

  final PraticaResumo pratica;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            practiceCategoryIcon(pratica.categoria),
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pratica.nome,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Icon(
            pratica.concluida ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: pratica.concluida ? AppColors.success : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Cabeçalho de bloco (número + título) ─────────────────────────────────────

class _CabecalhoBloco extends StatelessWidget {
  const _CabecalhoBloco({required this.numero, required this.titulo});

  final String numero;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            numero,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
