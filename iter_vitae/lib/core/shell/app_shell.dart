import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

// Cor do item ativo de navegação — identidade Rubrica.
// Aplicada tanto no BottomNavigationBar quanto no NavigationRail.
const _activeNavColor = AppColors.rubric;

/// Destinos da navegação principal.
class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

const _destinations = [
  _NavDestination(
    label: 'Hoje',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    route: '/hoje',
  ),
  _NavDestination(
    label: 'Plano',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
    route: '/regra-de-vida',
  ),
  _NavDestination(
    label: 'Leituras',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    route: '/leituras',
  ),
  _NavDestination(
    label: 'Direção',
    icon: Icons.favorite_border,
    selectedIcon: Icons.favorite,
    route: '/direcao',
  ),
  _NavDestination(
    label: 'Mais',
    icon: Icons.more_horiz,
    selectedIcon: Icons.more_horiz,
    route: '/mais',
  ),
];

/// Shell responsiva: BottomNavigationBar em mobile (< 600 px),
/// NavigationRail em tablet/desktop (≥ 600 px).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _destinations.indexWhere((d) => location.startsWith(d.route));
    return idx < 0 ? 0 : idx;
  }

  void _onTap(BuildContext context, int index) {
    context.go(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 600;
    final selectedIndex = _selectedIndex(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onTap(context, i),
              labelType: NavigationRailLabelType.all,
              indicatorColor: _activeNavColor.withValues(alpha: 0.12),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(
                        d.selectedIcon,
                        color: _activeNavColor,
                      ),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            VerticalDivider(
              width: 1,
              color: AppColors.divider,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        indicatorColor: _activeNavColor.withValues(alpha: 0.12),
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(
                  d.selectedIcon,
                  color: _activeNavColor,
                ),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
