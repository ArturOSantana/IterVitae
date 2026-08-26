import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/diary_entry.dart';
import '../../domain/repositories/diary_repository.dart';

/// Implementação Firestore do [DiaryRepository].
/// Caminho: /users/{uid}/diary/{entryId}
class FirestoreDiaryRepository implements DiaryRepository {
  FirestoreDiaryRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('diary');

  @override
  Future<List<DiaryEntry>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<DiaryEntry>> getForPeriod(DateTime from, DateTime to) async {
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
  Future<void> save(DiaryEntry entry) =>
      _col.doc(entry.id).set(_toMap(entry));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  // ── Serialização ──────────────────────────────────────────────────────────

  DiaryEntry _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DiaryEntry(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      text: d['text'] as String,
      tags: List<String>.from(d['tags'] as List? ?? []),
    );
  }

  Map<String, dynamic> _toMap(DiaryEntry e) => {
        'date': Timestamp.fromDate(e.date),
        'text': e.text,
        'tags': e.tags,
      };
}
