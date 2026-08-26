import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/reading_session_repository.dart';

/// Implementação Firestore do [ReadingSessionRepository].
/// Caminho: /users/{uid}/reading_sessions/{sessionId}
class FirestoreReadingSessionRepository implements ReadingSessionRepository {
  FirestoreReadingSessionRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('reading_sessions');

  @override
  Future<List<ReadingSession>> getForBook(String bookId) async {
    final snap = await _col
        .where('bookId', isEqualTo: bookId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<ReadingSession>> getForPeriod(
    DateTime from,
    DateTime to,
  ) async {
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
  Future<void> save(ReadingSession session) =>
      _col.doc(session.id).set(_toMap(session));

  // ── Serialização ──────────────────────────────────────────────────────────

  ReadingSession _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ReadingSession(
      id: doc.id,
      bookId: d['bookId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      startPage: d['startPage'] as int?,
      pagesRead: d['pagesRead'] as int?,
      minutesRead: d['minutesRead'] as int?,
      highlight: d['highlight'] as String?,
      application: d['application'] as String?,
    );
  }

  Map<String, dynamic> _toMap(ReadingSession s) => {
        'bookId': s.bookId,
        'date': Timestamp.fromDate(s.date),
        if (s.startPage != null) 'startPage': s.startPage,
        if (s.pagesRead != null) 'pagesRead': s.pagesRead,
        if (s.minutesRead != null) 'minutesRead': s.minutesRead,
        if (s.highlight != null) 'highlight': s.highlight,
        if (s.application != null) 'application': s.application,
      };
}
