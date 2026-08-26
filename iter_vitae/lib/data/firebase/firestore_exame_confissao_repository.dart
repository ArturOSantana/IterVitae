import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/exame_confissao_item.dart';
import '../../domain/entities/exame_confissao_sessao.dart';
import '../../domain/repositories/exame_confissao_repository.dart';
import '../in_memory/in_memory_exame_confissao_repository.dart';

/// Implementação Firestore do [ExameConfissaoRepository].
///
/// O catálogo de itens ([getCatalogo]) é seed data estático — não é persistido
/// no Firestore, sendo mantido igual à implementação InMemory.
///
/// Apenas as sessões do usuário são persistidas.
/// Caminho: /users/{uid}/exame_confissao_sessoes/{sessaoId}
class FirestoreExameConfissaoRepository implements ExameConfissaoRepository {
  FirestoreExameConfissaoRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  /// Reutiliza o catálogo seed do InMemory para não duplicar dados.
  final _seedRepo = InMemoryExameConfissaoRepository();

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection('users')
      .doc(uid)
      .collection('exame_confissao_sessoes');

  @override
  Future<List<ExameConfissaoItem>> getCatalogo() => _seedRepo.getCatalogo();

  @override
  Future<ExameConfissaoSessao?> getSessaoAtiva() async {
    final snap = await _col
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<void> saveSessao(ExameConfissaoSessao sessao) =>
      _col.doc(sessao.id).set(_toMap(sessao));

  // ── Serialização ──────────────────────────────────────────────────────────

  ExameConfissaoSessao _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ExameConfissaoSessao(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      itensMarcados: List<String>.from(d['itensMarcados'] as List? ?? []),
    );
  }

  Map<String, dynamic> _toMap(ExameConfissaoSessao s) => {
        'date': Timestamp.fromDate(s.date),
        'itensMarcados': s.itensMarcados,
      };
}
