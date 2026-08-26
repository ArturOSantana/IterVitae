import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/virtue.dart';
import '../../domain/repositories/virtue_repository.dart';

/// Implementação Firestore do [VirtueRepository].
/// Caminho: /users/{uid}/virtues/{virtueId}
class FirestoreVirtueRepository implements VirtueRepository {
  FirestoreVirtueRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('virtues');

  // ── Leitura ───────────────────────────────────────────────────────────────

  @override
  Future<Virtue?> getActiveVirtue() async {
    final snap = await _col
        .where('endDate', isNull: true)
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<List<Virtue>> getAll() async {
    final snap =
        await _col.orderBy('startDate', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  // ── Escrita ───────────────────────────────────────────────────────────────

  @override
  Future<void> save(Virtue virtue) =>
      _col.doc(virtue.id).set(_toMap(virtue));

  // ── Serialização ──────────────────────────────────────────────────────────

  Virtue _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Virtue(
      id: doc.id,
      name: d['name'] as String,
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: (d['endDate'] as Timestamp?)?.toDate(),
      purpose: d['purpose'] as String? ?? '',
      reflections: List<String>.from(d['reflections'] as List? ?? []),
    );
  }

  Map<String, dynamic> _toMap(Virtue v) => {
        'name': v.name,
        'startDate': Timestamp.fromDate(v.startDate),
        'endDate': v.endDate != null ? Timestamp.fromDate(v.endDate!) : null,
        'purpose': v.purpose,
        'reflections': v.reflections,
      };
}
