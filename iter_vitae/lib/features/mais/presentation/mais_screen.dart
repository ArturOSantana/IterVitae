import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Tela "Mais" — lista de atalhos para funcionalidades de uso não-diário.
///
/// Sem sub-abas, sem carrossel — lista simples de destinos, um por linha,
/// ícone + nome + chevron, com divisor hairline entre itens.
class MaisScreen extends StatelessWidget {
  const MaisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mais'),
        centerTitle: false,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _MaisItem(
                icon: Icons.book_outlined,
                label: 'Diário',
                route: '/mais/diario',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.shield_outlined,
                label: 'Lutas espirituais',
                route: '/mais/lutas',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.spa_outlined,
                label: 'Virtudes em foco',
                route: '/mais/virtudes',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.self_improvement_outlined,
                label: 'Exame diário',
                route: '/mais/exame-diario',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.checklist_outlined,
                label: 'Exame para confissão',
                route: '/mais/exame-confissao',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.event_note_outlined,
                label: 'Meios de formação',
                route: '/mais/meios',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Relatórios',
                route: '/mais/relatorios',
              ),
              _divider(),
              _MaisItem(
                icon: Icons.settings_outlined,
                label: 'Configurações',
                route: '/mais/configuracoes',
              ),
              _divider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.divider,
    );
  }
}

// ── Item de Lista Simples ───────────────────────────────────────────────────

class _MaisItem extends StatelessWidget {
  const _MaisItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        icon,
        size: 22,
        color: AppColors.primary,
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: () => context.push(route),
    );
  }
}
