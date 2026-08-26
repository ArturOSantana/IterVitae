import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/struggle.dart';
import '../../domain/repositories/struggle_repository.dart';

/// Implementação Firestore do [StruggleRepository].
/// Caminho: /users/{uid}/struggles/{struggleId}
class FirestoreStruggleRepository implements StruggleRepository {
  FirestoreStruggleRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('struggles');

  @override
  Future<Struggle?> getActive() async {
    final snap = await _col
        .where('status', isEqualTo: StruggleStatus.ativa.name)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<List<Struggle>> getAll() async {
    final snap = await _col.orderBy('startDate', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> save(Struggle struggle) =>
      _col.doc(struggle.id).set(_toMap(struggle));

  @override
  Future<void> logDaily(String struggleId, DailyStruggleLog log) async {
    final d = DateTime(log.date.year, log.date.month, log.date.day);
    final docRef = _col.doc(struggleId);

    // Lê o documento para remover log existente do mesmo dia (upsert diário)
    final snap = await docRef.get();
    if (!snap.exists) return;

    final rawLogs = (snap.data()!['dailyLogs'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((e) {
          final existing =
              DateTime.fromMillisecondsSinceEpoch(
                (e['date'] as Timestamp).millisecondsSinceEpoch,
              );
          final ed = DateTime(existing.year, existing.month, existing.day);
          return ed != d;
        })
        .toList()
      ..add({'date': Timestamp.fromDate(d), 'status': log.status.name});

    await docRef.update({'dailyLogs': rawLogs});
  }

  // ── Serialização ──────────────────────────────────────────────────────────

  Struggle _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawLogs = d['dailyLogs'] as List? ?? [];
    return Struggle(
      id: doc.id,
      title: d['title'] as String,
      status: StruggleStatus.values.byName(d['status'] as String),
      origemDirecaoId: d['origemDirecaoId'] as String?,
      encerradaEmDirecaoId: d['encerradaEmDirecaoId'] as String?,
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: (d['endDate'] as Timestamp?)?.toDate(),
      dailyLogs: rawLogs
          .map((e) => DailyStruggleLog(
                date: (e['date'] as Timestamp).toDate(),
                status: DailyStruggleStatus.values.byName(
                  e['status'] as String,
                ),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> _toMap(Struggle s) => {
        'title': s.title,
        'status': s.status.name,
        if (s.origemDirecaoId != null) 'origemDirecaoId': s.origemDirecaoId,
        if (s.encerradaEmDirecaoId != null)
          'encerradaEmDirecaoId': s.encerradaEmDirecaoId,
        'startDate': Timestamp.fromDate(s.startDate),
        if (s.endDate != null) 'endDate': Timestamp.fromDate(s.endDate!),
        'dailyLogs': s.dailyLogs
            .map((l) => {
                  'date': Timestamp.fromDate(l.date),
                  'status': l.status.name,
                })
            .toList(),
      };

}
