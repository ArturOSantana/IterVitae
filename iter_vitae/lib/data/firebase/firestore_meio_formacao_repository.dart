import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/meio_formacao.dart';
import '../../domain/repositories/meio_formacao_repository.dart';

/// Implementação Firestore do [MeioFormacaoRepository].
/// Caminho: /users/{uid}/meios_formacao/{meioId}
class FirestoreMeioFormacaoRepository implements MeioFormacaoRepository {
  FirestoreMeioFormacaoRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('meios_formacao');

  @override
  Future<List<MeioFormacao>> getAll() async {
    final snap = await _col.orderBy('data', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<MeioFormacao?> getProximo() async {
    final today = Timestamp.fromDate(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));
    final snap = await _col
        .where('data', isGreaterThanOrEqualTo: today)
        .orderBy('data')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<void> save(MeioFormacao meio) => _col.doc(meio.id).set(_toMap(meio));

  // ── Serialização ────────────────────────────────────────────────────────────

  MeioFormacao _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MeioFormacao(
      id: doc.id,
      tipo: TipoMeioFormacao.values.firstWhere(
        (t) => t.name == (d['tipo'] as String? ?? ''),
        orElse: () => TipoMeioFormacao.outro,
      ),
      titulo: d['titulo'] as String? ?? '',
      data: (d['data'] as Timestamp).toDate(),
      nota: d['nota'] as String?,
    );
  }

  Map<String, dynamic> _toMap(MeioFormacao m) => {
        'tipo': m.tipo.name,
        'titulo': m.titulo,
        'data': Timestamp.fromDate(m.data),
        if (m.nota != null) 'nota': m.nota,
      };
}
