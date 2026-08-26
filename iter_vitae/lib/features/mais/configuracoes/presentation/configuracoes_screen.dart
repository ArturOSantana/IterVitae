import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/auth/application/auth_controller.dart';
import 'package:iter_vitae/features/mais/calendario/application/calendar_export_controller.dart';
import 'package:iter_vitae/features/mais/configuracoes/application/diretor_controller.dart';
import 'package:iter_vitae/features/mais/configuracoes/application/notification_controller.dart';
import 'package:iter_vitae/features/mais/configuracoes/application/notification_prefs_controller.dart';
import 'package:iter_vitae/features/direction/application/enviar_relatorio_diretor.dart';
import 'package:iter_vitae/providers.dart';

/// Tela de Configurações — conta, diretor, notificações, exportação, sobre.
class ConfiguracoesScreen extends ConsumerWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Conta ──────────────────────────────────────────────────────
          _SectionLabel(label: 'Conta'),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.person_outline,
            label: 'Email',
            value: user?.email ?? '—',
          ),
          const SizedBox(height: 24),

          // ── Diretor espiritual ─────────────────────────────────────────
          _SectionLabel(label: 'Diretor espiritual'),
          const SizedBox(height: 8),
          _DiretorCard(ref: ref),
          const SizedBox(height: 8),
          const _VincularDiretorTile(),
          const SizedBox(height: 24),

          // ── Privacidade ────────────────────────────────────────────────
          _SectionLabel(label: 'Privacidade'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seus dados são privados.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nenhuma informação do diário, exame de consciência ou anotações é '
                    'compartilhada automaticamente. Você escolhe o que exportar e com quem '
                    'compartilhar.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Notificações ───────────────────────────────────────────────
          _SectionLabel(label: 'Notificações'),
          const SizedBox(height: 8),
          _NotificacoesCard(ref: ref),
          const SizedBox(height: 8),
          _NotificacoesExtrasCard(ref: ref),
          const SizedBox(height: 24),

          // ── Exportar calendário ────────────────────────────────────────
          _SectionLabel(label: 'Calendário'),
          const SizedBox(height: 8),
          _ExportarCalendarioCard(ref: ref),
          const SizedBox(height: 24),

          // ── Sobre ──────────────────────────────────────────────────────
          _SectionLabel(label: 'Sobre'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.info_outline,
                  label: 'Iter Vitae',
                  trailing: Text(
                    'v0.1.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  onTap: null,
                ),
                Divider(height: 1, indent: 56, color: AppColors.divider),
                _ActionTile(
                  icon: Icons.auto_stories_outlined,
                  label: '"Iter Vitae" — caminho da vida',
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Sair ───────────────────────────────────────────────────────
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair da conta'),
            onPressed: () => _confirmarSaida(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSaida(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text(
          'Seus dados estão salvos no Firebase e continuarão disponíveis '
          'ao fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    context.go('/login');
  }
}

// ── Card do diretor espiritual ────────────────────────────────────────────────

class _DiretorCard extends StatefulWidget {
  const _DiretorCard({required this.ref});
  final WidgetRef ref;

  @override
  State<_DiretorCard> createState() => _DiretorCardState();
}

class _DiretorCardState extends State<_DiretorCard> {
  final _nomeCtrl = TextEditingController();
  final _contatoCtrl = TextEditingController();
  final _paroquiaCtrl = TextEditingController();

  bool _editando = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _contatoCtrl.dispose();
    _paroquiaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diretorAsync = widget.ref.watch(diretorControllerProvider);
    final theme = Theme.of(context);

    return diretorAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (diretor) {
        // Inicializa campos na primeira carga
        if (!_initialized) {
          _nomeCtrl.text = diretor.nome ?? '';
          _contatoCtrl.text = diretor.contato ?? '';
          _paroquiaCtrl.text = diretor.paroquia ?? '';
          _initialized = true;
        }

        final temDiretor = diretor.nome?.isNotEmpty == true;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        temDiretor ? diretor.nome! : 'Nenhum diretor cadastrado',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: temDiretor
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    // Ícone de contato rápido (telefone/e-mail)
                    if (temDiretor &&
                        diretor.contato?.isNotEmpty == true) ...[
                      _ContatoIcon(contato: diretor.contato!),
                      const SizedBox(width: 4),
                    ],
                    TextButton(
                      onPressed: () => setState(() => _editando = !_editando),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_editando ? 'Cancelar' : 'Editar'),
                    ),
                  ],
                ),

                // Detalhes quando não está editando
                if (!_editando && temDiretor) ...[
                  if (diretor.contato?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      diretor.contato!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (diretor.paroquia?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      diretor.paroquia!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],

                // Formulário de edição
                if (_editando) ...[
                  const SizedBox(height: 12),
                  _CampoTexto(
                    controller: _nomeCtrl,
                    label: 'Nome',
                    hint: '',
                  ),
                  const SizedBox(height: 8),
                  _CampoTexto(
                    controller: _contatoCtrl,
                    label: 'Telefone ou e-mail',
                    hint: '',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 8),
                  _CampoTexto(
                    controller: _paroquiaCtrl,
                    label: 'Paróquia / comunidade',
                    hint: '',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: diretor.isSaving ? null : _salvar,
                      child: diretor.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _salvar() async {
    setState(() => _editando = false);
    await widget.ref.read(diretorControllerProvider.notifier).save(
          nome: _nomeCtrl.text,
          contato: _contatoCtrl.text,
          paroquia: _paroquiaCtrl.text,
        );
    _initialized = false; // Força re-leitura na próxima build
  }
}

class _ContatoIcon extends StatelessWidget {
  const _ContatoIcon({required this.contato});
  final String contato;

  @override
  Widget build(BuildContext context) {
    final isEmail = contato.contains('@');
    final isPhone =
        contato.startsWith('+') || RegExp(r'^\d').hasMatch(contato);

    if (!isEmail && !isPhone) return const SizedBox.shrink();

    return IconButton(
      onPressed: () => _abrir(context),
      icon: Icon(
        isEmail ? Icons.email_outlined : Icons.phone_outlined,
        size: 18,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Future<void> _abrir(BuildContext context) async {
    final isEmail = contato.contains('@');
    final uri = isEmail
        ? Uri.parse('mailto:$contato')
        : Uri.parse('tel:${contato.replaceAll(' ', '')}');

    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o app.')),
        );
      }
    }
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

// ── Card de notificações de práticas ─────────────────────────────────────────

class _NotificacoesCard extends StatelessWidget {
  const _NotificacoesCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationControllerProvider);
    final granted = notifAsync.valueOrNull?.permissionGranted ?? false;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  granted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 20,
                  color: granted ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lembretes de práticas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        granted
                            ? 'Notificações ativas para as práticas do plano.'
                            : 'Ative para receber lembretes nos horários programados.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!granted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: notifAsync.isLoading
                      ? null
                      : () => ref
                          .read(notificationControllerProvider.notifier)
                          .requestAndSync(),
                  child: notifAsync.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ativar notificações'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(notificationControllerProvider.notifier)
                      .syncWithPractices(),
                  child: const Text('Sincronizar com o plano de vida'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Card de notificações extras ───────────────────────────────────────────────

class _NotificacoesExtrasCard extends ConsumerStatefulWidget {
  const _NotificacoesExtrasCard({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_NotificacoesExtrasCard> createState() =>
      _NotificacoesExtrasCardState();
}

class _NotificacoesExtrasCardState
    extends ConsumerState<_NotificacoesExtrasCard> {
  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPrefsControllerProvider);
    final theme = Theme.of(context);

    return prefsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (prefs) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lembretes adicionais',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // ── Exame da noite ────────────────────────────────────────
              _NotifToggleRow(
                label: 'Exame da noite',
                sublabel: 'Como foi seu dia diante de Deus?',
                value: prefs.exameAtivo,
                onChanged: (v) => _update(prefs.copyWith(exameAtivo: v)),
              ),
              if (prefs.exameAtivo) ...[
                const SizedBox(height: 6),
                _HorarioRow(
                  hora: prefs.exameHora,
                  onEdit: () => _editarHora(
                    prefs,
                    prefs.exameHora,
                    (h) => prefs.copyWith(exameHora: h),
                  ),
                ),
              ],

              Divider(height: 24, color: AppColors.divider),

              // ── Direção espiritual ────────────────────────────────────
              _NotifToggleRow(
                label: 'Direção se aproximando',
                sublabel: 'Aviso antes do próximo encontro.',
                value: prefs.direcaoAtivo,
                onChanged: (v) => _update(prefs.copyWith(direcaoAtivo: v)),
              ),
              if (prefs.direcaoAtivo) ...[
                const SizedBox(height: 6),
                _DiasAntesRow(
                  dias: prefs.direcaoDiasAntes,
                  onChanged: (d) =>
                      _update(prefs.copyWith(direcaoDiasAntes: d)),
                ),
              ],

              Divider(height: 24, color: AppColors.divider),

              // ── Meios de formação ─────────────────────────────────────
              _NotifToggleRow(
                label: 'Meios de formação',
                sublabel: 'Aviso antes do próximo evento.',
                value: prefs.meiosAtivo,
                onChanged: (v) => _update(prefs.copyWith(meiosAtivo: v)),
              ),
              if (prefs.meiosAtivo) ...[
                const SizedBox(height: 6),
                _DiasAntesRow(
                  dias: prefs.meiosDiasAntes,
                  onChanged: (d) =>
                      _update(prefs.copyWith(meiosDiasAntes: d)),
                ),
              ],

              Divider(height: 24, color: AppColors.divider),

              // ── Confissão periódica ───────────────────────────────────
              _NotifToggleRow(
                label: 'Lembrete de confissão',
                sublabel:
                    'Cadência configurável. Mensal como sugestão padrão.',
                value: prefs.cadenciaConfissao !=
                    CadenciaConfissao.desativado,
                onChanged: (v) => _update(
                  prefs.copyWith(
                    cadenciaConfissao: v
                        ? CadenciaConfissao.mensal
                        : CadenciaConfissao.desativado,
                  ),
                ),
              ),
              if (prefs.cadenciaConfissao != CadenciaConfissao.desativado) ...[
                const SizedBox(height: 8),
                _CadenciaSelector(
                  atual: prefs.cadenciaConfissao,
                  onChanged: (c) =>
                      _update(prefs.copyWith(cadenciaConfissao: c)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _update(NotificationPrefs prefs) {
    ref
        .read(notificationPrefsControllerProvider.notifier)
        .savePrefs(prefs);
  }

  Future<void> _editarHora(
    NotificationPrefs prefs,
    String horaAtual,
    NotificationPrefs Function(String) updater,
  ) async {
    final parts = horaAtual.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 22,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
    );
    if (picked == null) return;
    final nova =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _update(updater(nova));
  }
}

class _NotifToggleRow extends StatelessWidget {
  const _NotifToggleRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              Text(sublabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primaryContainer,
        ),
      ],
    );
  }
}

class _HorarioRow extends StatelessWidget {
  const _HorarioRow({required this.hora, required this.onEdit});
  final String hora;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Horário: $hora',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEdit,
          child: Icon(Icons.edit_outlined,
              size: 14, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _DiasAntesRow extends StatelessWidget {
  const _DiasAntesRow({required this.dias, required this.onChanged});
  final int dias;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Avisar com:',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        ...[1, 2, 3, 5, 7].map(
          (d) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: Text('${d}d'),
              selected: dias == d,
              onSelected: (_) => onChanged(d),
              labelStyle: Theme.of(context).textTheme.labelSmall,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }
}

class _CadenciaSelector extends StatelessWidget {
  const _CadenciaSelector({required this.atual, required this.onChanged});
  final CadenciaConfissao atual;
  final ValueChanged<CadenciaConfissao> onChanged;

  @override
  Widget build(BuildContext context) {
    final opcoes = CadenciaConfissao.values
        .where((c) => c != CadenciaConfissao.desativado)
        .toList();

    return Wrap(
      spacing: 8,
      children: opcoes.map((c) {
        return ChoiceChip(
          label: Text(c.label),
          selected: atual == c,
          onSelected: (_) => onChanged(c),
          labelStyle: Theme.of(context).textTheme.labelSmall,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

// ── Card de exportação de calendário ─────────────────────────────────────────

class _ExportarCalendarioCard extends StatelessWidget {
  const _ExportarCalendarioCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarExportControllerProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exportar para calendário',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Gera um arquivo .ics com as práticas ativas. '
              'Exame, Diário e Luta não são incluídos por privacidade.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Calendários assinados (Google Agenda, Apple Calendário) '
              'atualizam periodicamente, não na hora — pode levar algumas '
              'horas para uma mudança aparecer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => ref
                        .read(calendarExportControllerProvider.notifier)
                        .exportAndShare(),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_outlined, size: 16),
                label: Text(
                    state.isLoading ? 'Gerando…' : 'Exportar .ics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textMuted),
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}

/// Tile que mostra o status do vínculo com o diretor e navega para a tela
/// de geração de código quando não há vínculo ainda.
class _VincularDiretorTile extends ConsumerWidget {
  const _VincularDiretorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temDirAsync = ref.watch(temDiretorVinculadoProvider);
    final temDiretor = temDirAsync.valueOrNull ?? false;

    return Card(
      child: ListTile(
        leading: Icon(
          temDiretor ? Icons.link : Icons.link_off_outlined,
          size: 20,
          color: temDiretor ? AppColors.success : AppColors.textMuted,
        ),
        title: Text(
          temDiretor ? 'Vinculado ao seu diretor' : 'Vincular ao meu diretor',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          temDiretor
              ? 'Vínculo ativo. Para desvincular, contate o suporte.'
              : 'Gere um código e informe ao seu diretor espiritual.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
        trailing: temDiretor
            ? null
            : const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textMuted),
        onTap: temDiretor
            ? null
            : () => context.push('/mais/vincular-diretor'),
        dense: true,
      ),
    );
  }
}
