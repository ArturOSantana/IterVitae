import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_pilcrow.dart';
import '../../../domain/entities/spiritual_direction.dart';
import '../../../providers.dart';
import '../application/struggle_service.dart';

/// Tela "Nova Luta" — criação de um novo [Struggle].
///
/// Identidade Rubrica: título em Fraunces, cabeçalhos via [SectionPilcrow],
/// seletor de origem com marcador circular em [AppColors.rubric], botão
/// outline em [AppColors.rubric]. Fundo neutro, sem cards com sombra.
///
/// Fluxo:
/// 1. Usuário preenche a descrição.
/// 2. Escolhe a origem: direção específica ou iniciativa própria.
/// 3. Ao tocar em "Começar esta luta":
///    - Se não há luta ativa → salva e volta.
///    - Se já há luta ativa → diálogo de confirmação antes de substituir.
class NewStruggleScreen extends ConsumerStatefulWidget {
  const NewStruggleScreen({super.key});

  @override
  ConsumerState<NewStruggleScreen> createState() => _NewStruggleScreenState();
}

class _NewStruggleScreenState extends ConsumerState<NewStruggleScreen> {
  final _descricaoCtrl = TextEditingController();

  // null = iniciativa própria; String = id da direção selecionada
  String? _origemDirecaoId;

  bool _saving = false;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  bool get _valido => _descricaoCtrl.text.trim().isNotEmpty;

  // ── Salvar ────────────────────────────────────────────────────────────────

  Future<void> _salvar() async {
    if (!_valido) return;
    setState(() => _saving = true);

    try {
      final criada = await StruggleService(ref).criarLuta(
        context,
        titulo: _descricaoCtrl.text.trim(),
        origemDirecaoId: _origemDirecaoId,
      );
      if (!criada) return; // usuário cancelou o diálogo
      if (!mounted) return;
      context.pop(); // ignore: use_build_context_synchronously
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final directionsAsync = ref.watch(_pastDirectionsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Nova luta',
          style: GoogleFonts.fraunces(
            fontSize: 20,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 40),
            children: [
              Divider(height: 1, color: AppColors.divider),

              // ── Campo descrição ────────────────────────────────────────────
              const SectionPilcrow(label: 'descrição'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextField(
                  controller: _descricaoCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 4),
              Divider(
                height: 24,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),

              // ── Seletor de origem ──────────────────────────────────────────
              const SectionPilcrow(label: 'origem'),
              const SizedBox(height: 4),

              directionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, e) => _OrigemOpcao(
                  label: 'Iniciativa própria, entre direções',
                  selecionada: _origemDirecaoId == null,
                  onTap: () => setState(() => _origemDirecaoId = null),
                ),
                data: (directions) => _OrigemSeletor(
                  directions: directions,
                  origemSelecionada: _origemDirecaoId,
                  onChanged: (id) => setState(() => _origemDirecaoId = id),
                ),
              ),

              Divider(
                height: 32,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),

              // ── Botão de ação ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BotaoIniciar(
                  habilitado: _valido && !_saving,
                  salvando: _saving,
                  onPressed: _salvar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Seletor de origem ─────────────────────────────────────────────────────────

/// Renderiza as opções de origem da luta.
///
/// - Se não há direções passadas: exibe apenas "Iniciativa própria",
///   pré-selecionada, sem lista vazia.
/// - Se há direções: exibe cada uma como opção rolável + a opção própria.
class _OrigemSeletor extends StatelessWidget {
  const _OrigemSeletor({
    required this.directions,
    required this.origemSelecionada,
    required this.onChanged,
  });

  final List<SpiritualDirection> directions;
  final String? origemSelecionada;
  final void Function(String? id) onChanged;

  @override
  Widget build(BuildContext context) {
    final passadas = directions
        .where((d) => d.foiRealizada)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // mais recente primeiro

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Direções passadas (se houver)
        for (final dir in passadas)
          _OrigemOpcao(
            label: _labelDirecao(dir),
            selecionada: origemSelecionada == dir.id,
            onTap: () => onChanged(dir.id),
          ),

        // Sempre presente: iniciativa própria
        _OrigemOpcao(
          label: 'Iniciativa própria, entre direções',
          selecionada: origemSelecionada == null,
          onTap: () => onChanged(null),
        ),
      ],
    );
  }

  String _labelDirecao(SpiritualDirection dir) {
    final data =
        DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(dir.date);
    final nome =
        dir.directorName != null ? ' com ${dir.directorName}' : '';
    return 'Combinada na direção de $data$nome';
  }
}

// ── Opção individual do seletor ───────────────────────────────────────────────

class _OrigemOpcao extends StatelessWidget {
  const _OrigemOpcao({
    required this.label,
    required this.selecionada,
    required this.onTap,
  });

  final String label;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Marcador circular estilo Rubrica
            _MarcadorCircular(selecionado: selecionada),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selecionada
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      selecionada ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Marcador circular (radio customizado Rubrica) ────────────────────────────

class _MarcadorCircular extends StatelessWidget {
  const _MarcadorCircular({required this.selecionado});

  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selecionado ? AppColors.rubric : AppColors.border,
          width: selecionado ? 1.5 : 1.5,
        ),
        color: selecionado
            ? AppColors.rubric.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      child: selecionado
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rubric,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Botão "Começar esta luta" ─────────────────────────────────────────────────

class _BotaoIniciar extends StatelessWidget {
  const _BotaoIniciar({
    required this.habilitado,
    required this.salvando,
    required this.onPressed,
  });

  final bool habilitado;
  final bool salvando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: habilitado ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.rubric,
        side: const BorderSide(color: AppColors.rubric),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: salvando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.rubric,
              ),
            )
          : const Text(
              'Começar esta luta',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }
}

// ── Provider auxiliar ─────────────────────────────────────────────────────────

/// Carrega todas as [SpiritualDirection] do repositório.
final _pastDirectionsProvider =
    FutureProvider.autoDispose<List<SpiritualDirection>>((ref) async {
  final repo = ref.read(directionRepositoryProvider);
  return repo.getAll();
});
