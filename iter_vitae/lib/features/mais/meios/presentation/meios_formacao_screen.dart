import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';
import 'package:iter_vitae/domain/entities/meio_formacao.dart';
import 'package:iter_vitae/providers.dart';

/// Provider local para a lista de [MeioFormacao].
final _meiosProvider = FutureProvider.autoDispose<List<MeioFormacao>>(
  (ref) => ref.read(meioFormacaoRepositoryProvider).getAll(),
);

final _proximoProvider = FutureProvider.autoDispose<MeioFormacao?>(
  (ref) => ref.read(meioFormacaoRepositoryProvider).getProximo(),
);

/// Tela Meios de formação.
///
/// Estrutura:
/// - Título "Meios de formação" (Fraunces 22 px)
/// - Botão "marcar próxima formação" (outline rubrica)
/// - ¶ próxima: próximo evento com borda esquerda rubrica
/// - ¶ realizados: eventos passados, do mais recente ao mais antigo
class MeiosFormacaoScreen extends ConsumerWidget {
  const MeiosFormacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximoAsync = ref.watch(_proximoProvider);
    final todosAsync = ref.watch(_meiosProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Meios de formação',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: CustomScrollView(
            slivers: [
              // Botão "marcar próxima formação"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/mais/meios/novo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rubric,
                      side: const BorderSide(color: AppColors.rubric),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('marcar próxima formação'),
                  ),
                ),
              ),

              // ¶ próxima
              const SliverToBoxAdapter(
                child: SectionPilcrow(label: 'próxima'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: proximoAsync.when(
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => const SizedBox.shrink(),
                    data: (proximo) => proximo == null
                        ? _EmptyProximo()
                        : _ProximoCard(meio: proximo),
                  ),
                ),
              ),

              // ¶ realizados
              const SliverToBoxAdapter(
                child: SectionPilcrow(label: 'realizados'),
              ),
              todosAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (todos) {
                  final passados = todos
                      .where((m) => m.data.isBefore(DateTime.now()))
                      .toList();
                  if (passados.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: Text(
                          'Nenhuma formação realizada ainda.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    );
                  }
                  return SliverList.separated(
                    itemCount: passados.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, i) =>
                        _RealizadoItem(meio: passados[i]),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ProximoCard extends StatelessWidget {
  const _ProximoCard({required this.meio});

  final MeioFormacao meio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(meio.data);

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final diff = meio.data.difference(today).inDays;
    final diffLabel = diff == 0
        ? 'hoje'
        : diff == 1
            ? 'amanhã'
            : 'em $diff dias';

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
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meio.tipo.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                diffLabel,
                style: GoogleFonts.fraunces(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.rubric,
                  height: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            meio.titulo,
            style: GoogleFonts.fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (meio.nota != null && meio.nota!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meio.nota!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyProximo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Nenhuma formação marcada.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

class _RealizadoItem extends StatelessWidget {
  const _RealizadoItem({required this.meio});

  final MeioFormacao meio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(meio.data);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              meio.titulo,
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            dateStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
