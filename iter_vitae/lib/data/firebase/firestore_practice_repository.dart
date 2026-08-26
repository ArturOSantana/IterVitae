import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/practice.dart';
import '../../domain/entities/practice_log.dart';
import '../../domain/repositories/practice_repository.dart';

/// Implementação Firestore do [PracticeRepository].
/// Caminho: /users/{uid}/practices/{practiceId}
///           /users/{uid}/practice_logs/{logId}
class FirestorePracticeRepository implements PracticeRepository {
  FirestorePracticeRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _practices =>
      _db.collection('users').doc(uid).collection('practices');

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('users').doc(uid).collection('practice_logs');

  // ── Leitura ───────────────────────────────────────────────────────────────

  @override
  Future<List<Practice>> getActivePractices() async {
    final snap = await _practices.where('active', isEqualTo: true).get();
    return snap.docs.map(_practiceFromDoc).toList();
  }

  @override
  Future<List<Practice>> getAllPractices() async {
    final snap = await _practices.get();
    return snap.docs.map(_practiceFromDoc).toList();
  }

  @override
  Future<List<Practice>> getPracticesByCategory(
    PracticeCategory category,
  ) async {
    final snap = await _practices
        .where('active', isEqualTo: true)
        .where('category', isEqualTo: category.name)
        .get();
    return snap.docs.map(_practiceFromDoc).toList();
  }

  @override
  Future<PracticeLog?> getLogForDate(
    String practiceId,
    DateTime date,
  ) async {
    final d = DateTime(date.year, date.month, date.day);
    final snap = await _logs
        .where('practiceId', isEqualTo: practiceId)
        .where('date', isEqualTo: Timestamp.fromDate(d))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _logFromDoc(snap.docs.first);
  }

  @override
  Future<List<PracticeLog>> getLogsForPeriod(
    DateTime from,
    DateTime to,
  ) async {
    final start = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final end = Timestamp.fromDate(
      DateTime(to.year, to.month, to.day, 23, 59, 59),
    );
    final snap = await _logs
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.map(_logFromDoc).toList();
  }

  // ── Escrita ───────────────────────────────────────────────────────────────

  @override
  Future<void> saveLog(PracticeLog log) =>
      _logs.doc(log.id).set(_logToMap(log));

  @override
  Future<void> savePractice(Practice practice) =>
      _practices.doc(practice.id).set(_practiceToMap(practice));

  @override
  Future<void> deactivatePractice(String practiceId) =>
      _practices.doc(practiceId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Serialização ──────────────────────────────────────────────────────────

  Practice _practiceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Practice(
      id: doc.id,
      name: d['name'] as String,
      category: PracticeCategory.values.byName(d['category'] as String),
      type: PracticeType.values.byName(d['type'] as String),
      scheduledTime: d['scheduledTime'] as String,
      frequency: PracticeFrequency.values.byName(
        d['frequency'] as String? ?? 'daily',
      ),
      weekdays: List<int>.from(d['weekdays'] as List? ?? []),
      active: d['active'] as bool? ?? true,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _practiceToMap(Practice p) => {
        'name': p.name,
        'category': p.category.name,
        'type': p.type.name,
        'scheduledTime': p.scheduledTime,
        'frequency': p.frequency.name,
        'weekdays': p.weekdays,
        'active': p.active,
        'updatedAt': p.updatedAt != null
            ? Timestamp.fromDate(p.updatedAt!)
            : FieldValue.serverTimestamp(),
      };

  PracticeLog _logFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PracticeLog(
      id: doc.id,
      practiceId: d['practiceId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      completed: d['completed'] as bool,
      skipReason: d['skipReason'] as String?,
      reflection: d['reflection'] as String?,
      duration: d['duration'] as int?,
      lights: d['lights'] as String?,
    );
  }

  Map<String, dynamic> _logToMap(PracticeLog l) => {
        'practiceId': l.practiceId,
        'date': Timestamp.fromDate(
          DateTime(l.date.year, l.date.month, l.date.day),
        ),
        'completed': l.completed,
        if (l.skipReason != null) 'skipReason': l.skipReason,
        if (l.reflection != null) 'reflection': l.reflection,
        if (l.duration != null) 'duration': l.duration,
        if (l.lights != null) 'lights': l.lights,
      };
}
