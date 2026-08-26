import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/hoje/presentation/hoje_screen.dart';
import '../../features/life_plan/presentation/life_plan_screen.dart';
import '../../features/mais/presentation/mais_screen.dart';
import '../../features/mais/diario/presentation/diario_screen.dart';
import '../../features/mais/diario/presentation/diario_entry_screen.dart';
import '../../domain/entities/diary_entry.dart';
import '../../features/mais/virtudes/presentation/virtudes_screen.dart';
import '../../features/mais/exame/presentation/exame_diario_screen.dart';
import '../../features/mais/exame/presentation/exame_confissao_screen.dart';
import '../../features/mais/meios/presentation/meios_formacao_screen.dart';
import '../../features/mais/meios/presentation/meio_formacao_form_screen.dart';
import '../../features/mais/configuracoes/presentation/configuracoes_screen.dart';
import '../../features/readings/presentation/readings_screen.dart';
import '../../features/readings/presentation/book_detail_screen.dart';
import '../../domain/entities/spiritual_direction.dart';
import '../../features/direction/presentation/direction_screen.dart';
import '../../features/direction/presentation/quick_note_screen.dart';
import '../../features/direction/presentation/register_direction_screen.dart';
import '../../features/hoje/presentation/luta_semana_screen.dart';
import '../../features/struggle/presentation/new_struggle_screen.dart';
import '../../features/mais/lutas/presentation/lutas_screen.dart';
import '../../features/mais/calendario/presentation/calendario_screen.dart';
import '../../providers.dart';
import '../shell/app_shell.dart';
import '../../core/theme/app_colors.dart';

/// Provider do [GoRouter].
/// Criado como [Provider] Riverpod para que o [Ref] nativo esteja disponível
/// no guard de autenticação e no [_AuthListenable], sem precisar de [WidgetRef].
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/hoje',
    redirect: (context, state) {
      final authAsync = ref.read(currentUserProvider);
      final isLoggedIn = authAsync.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (authAsync.isLoading) return null;
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/hoje';
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/hoje',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HojeScreen()),
          ),
          GoRoute(
            path: '/regra-de-vida',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LifePlanScreen()),
          ),
          GoRoute(
            path: '/leituras',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReadingsScreen()),
            routes: [
              GoRoute(
                path: 'detalhe/:bookId',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId']!;
                  return BookDetailScreen(bookId: bookId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/direcao',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DirectionScreen()),
            routes: [
              GoRoute(
                path: 'registrar',
                builder: (context, state) => RegisterDirectionScreen(
                  existing: state.extra as SpiritualDirection?,
                ),
              ),
              GoRoute(
                path: 'anotar',
                builder: (context, state) => QuickNoteScreen(
                  direction: state.extra as SpiritualDirection,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/luta-semana',
            builder: (context, state) => const LutaSemanaScreen(),
          ),
          GoRoute(
            path: '/nova-luta',
            builder: (context, state) => const NewStruggleScreen(),
          ),
          GoRoute(
            path: '/mais',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MaisScreen()),
            routes: [
              GoRoute(
                path: 'diario',
                builder: (context, state) => const DiarioScreen(),
                routes: [
                  GoRoute(
                    path: 'nova',
                    builder: (context, state) => DiarioEntryScreen(
                      existing: state.extra as DiaryEntry?,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'lutas',
                builder: (context, state) => const LutasScreen(),
              ),
              GoRoute(
                path: 'virtudes',
                builder: (context, state) => const VirtudesScreen(),
              ),
              GoRoute(
                path: 'exame-diario',
                builder: (context, state) => const ExameDiarioScreen(),
              ),
              GoRoute(
                path: 'exame-confissao',
                builder: (context, state) => const ExameConfissaoScreen(),
              ),
              GoRoute(
                path: 'meios',
                builder: (context, state) => const MeiosFormacaoScreen(),
                routes: [
                  GoRoute(
                    path: 'novo',
                    builder: (context, state) => const MeioFormacaoFormScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'relatorios',
                builder: (context, state) =>
                    const _StubScreen(label: 'Relatórios'),
              ),
              GoRoute(
                path: 'calendario',
                builder: (context, state) => const CalendarioScreen(),
              ),
              GoRoute(
                path: 'configuracoes',
                builder: (context, state) => const ConfiguracoesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Descarta o router ao invalidar o provider
  ref.onDispose(router.dispose);
  return router;
});

/// Notifica o GoRouter quando o estado de auth muda.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AsyncValue>(currentUserProvider, (prev, next) {
      notifyListeners();
    });
  }
}

/// Tela stub para rotas ainda não implementadas.
class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Em breve',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

