import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/reflection.dart';
import '../../../../providers.dart';

/// Campos do exame de consciência completo.
class ExameState {
  const ExameState({
    required this.date,
    this.agradecimento = '',
    this.presencaDeDeus = '',
    this.luzes = '',
    this.quedas = '',
    this.proposito = '',
    this.isSaved = false,
    this.isSaving = false,
  });

  final DateTime date;

  /// 1. Agradecimento — graças recebidas no dia.
  final String agradecimento;

  /// 2. Presença de Deus — como Deus esteve presente.
  final String presencaDeDeus;

  /// 3. Fidelidade / luzes recebidas — puxado automaticamente da prática contemplativa.
  final String luzes;

  /// 4. Quedas — o que foi difícil, pecados, falhas.
  final String quedas;

  /// 5. Propósito de amanhã — resolução concreta para o dia seguinte.
  final String proposito;

  /// Se o exame de hoje já foi salvo anteriormente.
  final bool isSaved;

  final bool isSaving;

  ExameState copyWith({
    DateTime? date,
    String? agradecimento,
    String? presencaDeDeus,
    String? luzes,
    String? quedas,
    String? proposito,
    bool? isSaved,
    bool? isSaving,
  }) {
    return ExameState(
      date: date ?? this.date,
      agradecimento: agradecimento ?? this.agradecimento,
      presencaDeDeus: presencaDeDeus ?? this.presencaDeDeus,
      luzes: luzes ?? this.luzes,
      quedas: quedas ?? this.quedas,
      proposito: proposito ?? this.proposito,
      isSaved: isSaved ?? this.isSaved,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Serializa os campos num texto único para persistir na [Reflection].
  String toReflectionText() {
    final buf = StringBuffer();
    if (agradecimento.isNotEmpty) buf.writeln('**Agradecimento**\n$agradecimento\n');
    if (presencaDeDeus.isNotEmpty) buf.writeln('**Presença de Deus**\n$presencaDeDeus\n');
    if (luzes.isNotEmpty) buf.writeln('**Luzes recebidas**\n$luzes\n');
    if (quedas.isNotEmpty) buf.writeln('**Quedas**\n$quedas\n');
    if (proposito.isNotEmpty) buf.writeln('**Propósito de amanhã**\n$proposito');
    return buf.toString().trim();
  }
}

/// Controller do Exame de Consciência.
class ExameController extends AsyncNotifier<ExameState> {
  @override
  Future<ExameState> build() async {
    final today = DateTime.now();
    final existing = await ref.watch(reflectionRepositoryProvider).getForDate(today);
    if (existing == null) {
      return ExameState(date: today);
    }
    // Exame já salvo hoje — reconstrói estado a partir do texto salvo
    return ExameState(
      date: today,
      luzes: existing.text,
      isSaved: true,
    );
  }

  /// Salva o exame completo como uma [Reflection] no repositório.
  Future<void> save(ExameState fields) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(fields.copyWith(isSaving: true));

    final text = fields.toReflectionText();
    if (text.isEmpty) {
      state = AsyncData(fields.copyWith(isSaving: false));
      return;
    }

    final reflection = Reflection(
      id: 'exame_${fields.date.millisecondsSinceEpoch}',
      date: fields.date,
      text: text,
    );

    try {
      await ref.read(reflectionRepositoryProvider).save(reflection);
      state = AsyncData(fields.copyWith(isSaving: false, isSaved: true));
    } catch (_) {
      state = AsyncData(current.copyWith(isSaving: false));
    }
  }
}

/// Provider do [ExameController].
final exameControllerProvider =
    AsyncNotifierProvider<ExameController, ExameState>(ExameController.new);
