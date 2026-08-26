import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reflection.dart';
import '../../domain/repositories/reflection_repository.dart';

/// Implementação Firestore do [ReflectionRepository].
/// Caminho: /users/{uid}/reflections/{reflectionId}
class FirestoreReflectionRepository implements ReflectionRepository {
  FirestoreReflectionRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('reflections');

  @override
  Future<Reflection?> getForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final snap = await _col
        .where('date', isEqualTo: Timestamp.fromDate(d))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<List<Reflection>> getForPeriod(DateTime from, DateTime to) async {
    final start = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final end = Timestamp.fromDate(
      DateTime(to.year, to.month, to.day, 23, 59, 59),
    );
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> save(Reflection reflection) =>
      _col.doc(reflection.id).set(_toMap(reflection));

  // ── Serialização ──────────────────────────────────────────────────────────

  Reflection _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Reflection(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      text: d['text'] as String,
    );
  }

  Map<String, dynamic> _toMap(Reflection r) => {
        'date': Timestamp.fromDate(
          DateTime(r.date.year, r.date.month, r.date.day),
        ),
        'text': r.text,
      };
}
