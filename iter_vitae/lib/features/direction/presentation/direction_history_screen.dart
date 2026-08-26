import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/spiritual_direction.dart';
import 'package:iter_vitae/features/direction/application/direction_history_controller.dart';

/// Visão "Histórico" da aba Direção.
///
/// Lista as direções já realizadas (mais recente primeiro), com botão
/// para registrar uma nova direção realizada.
class DirectionHistoryScreen extends ConsumerWidget {
  const DirectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(directionHistoryControllerProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar o histórico.\nTente novamente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      data: (directions) => _HistoryContent(directions: directions),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.directions});

  final List<SpiritualDirection> directions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Botão registrar direção realizada — outline rubrica, largura total, sem ícone
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/direcao/registrar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rubric,
                side: const BorderSide(color: AppColors.rubric, width: 0.5),
              ),
              child: const Text('registrar direção realizada'),
            ),
          ),
        ),

        Divider(height: 1, color: AppColors.divider),

        if (directions.isEmpty)
          _EmptyHistory()
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '${directions.length} ${directions.length == 1 ? 'direção registrada' : 'direções registradas'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          ...directions.asMap().entries.map((entry) {
            final index = entry.key;
            final direction = entry.value;
            final sequentialNumber = directions.length - index;
            return Column(
              children: [
                DirectionHistoryCard(
                  direction: direction,
                  sequentialNumber: sequentialNumber,
                ),
                Divider(height: 1, color: AppColors.divider),
              ],
            );
          }),
        ],
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Suas direções aparecerão aqui\ndepois de registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card expansível de uma direção já realizada.
class DirectionHistoryCard extends ConsumerWidget {
  const DirectionHistoryCard({
    super.key,
    required this.direction,
    required this.sequentialNumber,
  });

  final SpiritualDirection direction;
  final int sequentialNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat('d/MM/yyyy', 'pt_BR');

    final pontos = direction.pontosTrabalhados;
    final resumo = (pontos != null && pontos.isNotEmpty)
        ? pontos
        : 'Início do acompanhamento';

    final proximaStr = direction.nextDate != null
        ? fmt.format(direction.nextDate!)
        : 'a definir';

    final semanticLabel =
        'Direção #${sequentialNumber.toString().padLeft(2, '0')}, '
        '${fmt.format(direction.date)}, $resumo';

    return Semantics(
      label: semanticLabel,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direção #${sequentialNumber.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(direction.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textMuted,
              tooltip: 'Editar registro',
              onPressed: () => context.push(
                '/direcao/registrar',
                extra: direction,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resumo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Próxima: $proximaStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        children: [_DirectionDetail(direction: direction)],
      ),
    );
  }
}

/// Conteúdo expandido do card: orientações e propósitos.
class _DirectionDetail extends StatelessWidget {
  const _DirectionDetail({required this.direction});

  final SpiritualDirection direction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientacoes = direction.orientacoesRecebidas;
    final propositos = direction.propositosCombinados;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orientacoes != null && orientacoes.isNotEmpty) ...[
            _DetailLabel(label: 'Orientações recebidas'),
            const SizedBox(height: 6),
            Text(orientacoes, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],
          if (propositos.isNotEmpty) ...[
            _DetailLabel(label: 'Propósitos combinados'),
            const SizedBox(height: 6),
            ...propositos.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· ', style: TextStyle(color: AppColors.primary)),
                    Expanded(
                      child: Text(p, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((orientacoes == null || orientacoes.isEmpty) && propositos.isEmpty)
            Text(
              'Nenhum detalhe registrado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
    );
  }
}
