import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/exame_diario.dart';
import '../../domain/repositories/exame_diario_repository.dart';

/// Implementação Firestore do [ExameDiarioRepository].
/// Caminho: /users/{uid}/exame_diario/{exameId}
class FirestoreExameDiarioRepository implements ExameDiarioRepository {
  FirestoreExameDiarioRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('exame_diario');

  @override
  Future<ExameDiario?> getForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final snap = await _col
        .where('date', isEqualTo: Timestamp.fromDate(d))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<List<ExameDiario>> getWeek(DateTime startOfWeek) async {
    final start = Timestamp.fromDate(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
    );
    final end = Timestamp.fromDate(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59),
    );
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> save(ExameDiario exame) =>
      _col.doc(exame.id).set(_toMap(exame));

  // ── Serialização ──────────────────────────────────────────────────────────

  ExameDiario _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ExameDiario(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      gratidao: d['gratidao'] as String? ?? '',
      revisaoDia: d['revisaoDia'] as String? ?? '',
      arrependimento: d['arrependimento'] as String? ?? '',
      proposito: d['proposito'] as String? ?? '',
    );
  }

  Map<String, dynamic> _toMap(ExameDiario e) => {
        'date': Timestamp.fromDate(
          DateTime(e.date.year, e.date.month, e.date.day),
        ),
        'gratidao': e.gratidao,
        'revisaoDia': e.revisaoDia,
        'arrependimento': e.arrependimento,
        'proposito': e.proposito,
      };
}
