import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';
import 'package:iter_vitae/domain/entities/meio_formacao.dart';
import 'package:iter_vitae/features/hoje/application/hoje_controller.dart';
import 'package:iter_vitae/providers.dart';
import 'widgets/jaculatoria_card.dart';
import 'widgets/practice_list_item.dart';
import 'widgets/progress_card.dart';
import 'widgets/struggle_card.dart';
import 'widgets/virtue_banner.dart';

/// Tela Hoje — dashboard diário do Iter Vitae.
///
/// Ordem visual:
///   1. Saudação + data
///   2. ProgressCard
///   3. StruggleCard (se houver luta ativa)
///   4. Lista de práticas
///   5. VirtueBanner (se houver virtude em foco)
///   6. ReflectionInput
///
/// Edge cases:
///   - [HojeState.isEmpty]: exibe mensagem para configurar práticas
///   - [HojeState.isAllComplete]: ProgressCard muda de cor
class HojeScreen extends ConsumerWidget {
  const HojeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hojeControllerProvider);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar o dia.\nTente novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
      data: (state) => Scaffold(
        appBar: AppBar(
          title: _DateHeader(date: state.date),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              tooltip: 'Opções',
            ),
          ],
        ),
        body: state.isEmpty
            ? _EmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // 1. Jaculatória do dia
                  const JaculatoriaDoDia(),
                  const SizedBox(height: 16),

                  // 2. Progresso
                  ProgressCard(
                    completed: state.completedCount,
                    total: state.totalCount,
                  ),
                  const SizedBox(height: 12),

                  // 2. Luta ativa (ou convite quando não há)
                  if (state.activeStruggle != null) ...[
                    StruggleCard(
                      struggle: state.activeStruggle!,
                      todayStatus: state.todayStruggleLog?.status,
                      onMark: (status) => ref
                          .read(hojeControllerProvider.notifier)
                          .markStruggle(
                            state.activeStruggle!.id,
                            status,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _SemLutaConvite(),
                    const SizedBox(height: 12),
                  ],

                  // 3. Práticas do dia — título via SectionPilcrow
                  const SectionPilcrow(label: 'práticas de hoje'),
                  const SizedBox(height: 4),
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < state.practices.length; i++) ...[
                          PracticeListItem(
                            practice: state.practices[i],
                            log: state.logs[state.practices[i].id],
                            onComplete: () => ref
                                .read(hojeControllerProvider.notifier)
                                .completePractice(state.practices[i].id),
                          ),
                          if (i < state.practices.length - 1)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppColors.divider,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Lembrete de formação próxima (dentro dos próximos 7 dias)
                  _MeiosLembrete(),

                  const SizedBox(height: 16),

                  // 4. Virtude a ser exercida
                  if (state.currentVirtue != null) ...[
                    VirtueBanner(virtue: state.currentVirtue!),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

/// Lembrete discreto de formação próxima.
///
/// Exibe "¶ [tipo] em X dias" em Fraunces itálico rubrica quando o próximo
/// [MeioFormacao] está dentro dos próximos 7 dias. Tocável → /mais/meios.
class _MeiosLembrete extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meioFormacaoRepositoryProvider);
    return FutureBuilder(
      future: async.getProximo(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
        final proximo = snap.data!;
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        final diff = proximo.data.difference(today).inDays;
        if (diff < 0 || diff > 7) return const SizedBox.shrink();

        final label = diff == 0
            ? '${proximo.tipo.label.toLowerCase()} hoje'
            : diff == 1
                ? '${proximo.tipo.label.toLowerCase()} amanhã'
                : '${proximo.tipo.label.toLowerCase()} em $diff dias';

        return GestureDetector(
          onTap: () => context.push('/mais/meios'),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '¶ $label',
              style: GoogleFonts.fraunces(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.rubric,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}


class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meu caminho hoje',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          formatted,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Convite discreto para adicionar uma luta quando não há luta ativa.
/// Mesmo estilo do StruggleCard — borda esquerda rubrica, fundo neutro.
class _SemLutaConvite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: const BorderSide(color: AppColors.rubric, width: 2),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '¶ luta atual',
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.rubric,
                height: 1.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/nova-luta'),
            child: Text(
              'adicionar uma luta',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.rubric,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhuma prática configurada.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
