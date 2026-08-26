import '../../domain/entities/exame_confissao_item.dart';
import '../../domain/entities/exame_confissao_sessao.dart';
import '../../domain/repositories/exame_confissao_repository.dart';

/// Implementação em memória do [ExameConfissaoRepository].
///
/// O catálogo de itens é seed data inspirado no exame tradicional
/// pelos Dez Mandamentos — tom interrogativo, sem julgamento estrutural.
/// TODO: substituir por FirestoreExameConfissaoRepository.
class InMemoryExameConfissaoRepository implements ExameConfissaoRepository {
  static final List<ExameConfissaoItem> _catalogo = _buildCatalogo();

  final List<ExameConfissaoSessao> _sessoes = [];

  @override
  Future<List<ExameConfissaoItem>> getCatalogo() async => List.unmodifiable(_catalogo);

  @override
  Future<ExameConfissaoSessao?> getSessaoAtiva() async {
    if (_sessoes.isEmpty) return null;
    return _sessoes.last;
  }

  @override
  Future<void> saveSessao(ExameConfissaoSessao sessao) async {
    final index = _sessoes.indexWhere((s) => s.id == sessao.id);
    if (index >= 0) {
      _sessoes[index] = sessao;
    } else {
      _sessoes.add(sessao);
    }
  }

  // ── Seed data ────────────────────────────────────────────────────────────

  static List<ExameConfissaoItem> _buildCatalogo() {
    const raw = [
      // ── Amor a Deus ──────────────────────────────────────────────────────
      (
        cat: 'Amor a Deus',
        itens: [
          'Negligenciei a oração ou a fiz apenas por rotina, sem empenho real?',
          'Duvidei da fé, desesperei ou murmurei contra Deus nas dificuldades?',
          'Profanei o nome de Deus, de Nossa Senhora ou dos santos em vão?',
          'Deixei de guardar o domingo e os dias santos com descanso e culto a Deus?',
          'Pratiquei superstição, recorri a ocultismo ou atribuí poderes mágicos a objetos?',
        ]
      ),
      // ── Amor ao próximo ──────────────────────────────────────────────────
      (
        cat: 'Amor ao próximo',
        itens: [
          'Desonrei ou fui desrespeitoso com meus pais ou superiores legítimos?',
          'Causei dano físico ou moral a alguém — por violência, negligência ou descuido?',
          'Dei ocasião de pecado a outrem, escandalizei ou induzi alguém ao mal?',
          'Fui impuro em pensamentos que voluntariamente retive, em palavras ou ações?',
          'Tomei, devolvi com dano ou retive indevidamente o que era de outro?',
          'Fiz juízos temerários, murmurei, detratei ou revelei segredo alheio?',
          'Dei falso testemunho, menti com dano a outrem ou faltei à minha palavra?',
          'Invejei o bem alheio ou cobicei o que pertencia ao próximo?',
        ]
      ),
      // ── Amor a si mesmo ──────────────────────────────────────────────────
      (
        cat: 'Amor a si mesmo',
        itens: [
          'Cedi à gula, ao excesso com alimentos, bebida ou outras substâncias?',
          'Fui dominado pela preguiça, negligenciei deveres ou desperdicei o tempo?',
          'Agi por vaidade, busquei reconhecimento de modo desordenado?',
          'Deixei crescer ira, rancor ou recusei-me a perdoar?',
          'Negligenciei minha saúde ou coloquei minha vida em risco desnecessariamente?',
        ]
      ),
      // ── Vida sacramental ─────────────────────────────────────────────────
      (
        cat: 'Vida sacramental',
        itens: [
          'Deixei de me confessar quando estava em pecado grave e me aproximei da comunhão?',
          'Recebi algum sacramento sem a devida disposição interior?',
          'Negligenciei minha formação espiritual e o aprofundamento da fé?',
          'Deixei de cumprir as penitências ou resoluções assumidas na última confissão?',
        ]
      ),
      // ── Vida apostólica ──────────────────────────────────────────────────
      (
        cat: 'Vida apostólica',
        itens: [
          'Fui omisso diante de uma injustiça que podia corrigir ou denunciar?',
          'Deixei de dar testemunho de fé quando me era possível e conveniente?',
          'Negligenciei compromissos assumidos com a comunidade ou com o diretor espiritual?',
        ]
      ),
    ];

    final items = <ExameConfissaoItem>[];
    for (final group in raw) {
      for (var i = 0; i < group.itens.length; i++) {
        final catSlug = group.cat
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z_]'), '');
        items.add(ExameConfissaoItem(
          id: '${catSlug}_$i',
          categoria: group.cat,
          texto: group.itens[i],
          ordem: i,
        ));
      }
    }
    return List.unmodifiable(items);
  }
}
