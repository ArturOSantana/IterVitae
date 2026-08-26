import '../../domain/entities/meio_formacao.dart';
import '../../domain/repositories/meio_formacao_repository.dart';

/// Implementação em memória de [MeioFormacaoRepository].
///
/// Inicializa com 3 registros mock (2 passados + 1 futuro) para
/// facilitar o desenvolvimento sem backend.
class InMemoryMeioFormacaoRepository implements MeioFormacaoRepository {
  InMemoryMeioFormacaoRepository() {
    _seed();
  }

  final List<MeioFormacao> _items = [];

  void _seed() {
    final now = DateTime.now();
    _items.addAll([
      MeioFormacao(
        id: 'meio_001',
        tipo: TipoMeioFormacao.retiro,
        titulo: 'Retiro anual de agosto',
        data: DateTime(now.year - 1, 8, 15),
        nota: 'Retiro de três dias em silêncio. Muita clareza sobre a oração.',
      ),
      MeioFormacao(
        id: 'meio_002',
        tipo: TipoMeioFormacao.recolhimento,
        titulo: 'Recolhimento mensal — ${_mesLabel(now.month - 1)}',
        data: DateTime(now.year, now.month - 1 < 1 ? 12 : now.month - 1, 20),
        nota: 'Foco nos pontos combinados com o padre.',
      ),
      MeioFormacao(
        id: 'meio_003',
        tipo: TipoMeioFormacao.recolhimento,
        titulo: 'Recolhimento mensal — ${_mesLabel(now.month + 1 > 12 ? 1 : now.month + 1)}',
        data: DateTime(now.year, now.month + 1 > 12 ? 1 : now.month + 1, 20),
      ),
    ]);
  }

  static String _mesLabel(int month) {
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return meses[(month - 1).clamp(0, 11)];
  }

  @override
  Future<List<MeioFormacao>> getAll() async {
    final sorted = List<MeioFormacao>.from(_items)
      ..sort((a, b) => b.data.compareTo(a.data));
    return sorted;
  }

  @override
  Future<MeioFormacao?> getProximo() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final futuros = _items
        .where((m) => !m.data.isBefore(today))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    return futuros.isEmpty ? null : futuros.first;
  }

  @override
  Future<void> save(MeioFormacao meio) async {
    final index = _items.indexWhere((m) => m.id == meio.id);
    if (index >= 0) {
      _items[index] = meio;
    } else {
      _items.add(meio);
    }
  }
}
