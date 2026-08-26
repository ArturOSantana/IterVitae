import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/spiritual_direction.dart';
import '../../domain/repositories/direction_repository.dart';

/// Implementação Firestore do [DirectionRepository].
/// Caminho: /users/{uid}/directions/{directionId}
class FirestoreDirectionRepository implements DirectionRepository {
  FirestoreDirectionRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('directions');

  @override
  Future<List<SpiritualDirection>> getAll() async {
    final snap = await _col.orderBy('date').get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<SpiritualDirection?> getLastPast() async {
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    final snap = await _col
        .where('date', isLessThan: Timestamp.fromDate(today0))
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<SpiritualDirection?> getNext() async {
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today0))
        .orderBy('date')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<SpiritualDirection> getOrCreateNext() async {
    final existing = await getNext();
    if (existing != null) return existing;

    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    // Cria nova direção em branco 30 dias à frente
    final newRef = _col.doc();
    final newDir = SpiritualDirection(
      id: newRef.id,
      date: today0.add(const Duration(days: 30)),
    );
    await newRef.set(_toMap(newDir));
    return newDir;
  }

  @override
  Future<void> save(SpiritualDirection direction) =>
      _col.doc(direction.id).set(_toMap(direction));

  // ── Serialização ──────────────────────────────────────────────────────────

  SpiritualDirection _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final rawQuestions = d['questions'] as List? ?? [];
    final rawNotes = d['notasPreparacao'] as Map<String, dynamic>? ?? {};
    final rawPropositos = d['propositosCombinados'] as List? ?? [];

    return SpiritualDirection(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      directorName: d['directorName'] as String?,
      diretorContato: d['diretorContato'] as String?,
      diretorParoquia: d['diretorParoquia'] as String?,
      nextDate: (d['nextDate'] as Timestamp?)?.toDate(),
      questions: rawQuestions
          .map((q) => DirectionQuestion(
                id: q['id'] as String,
                text: q['text'] as String,
                resolved: q['resolved'] as bool? ?? false,
              ))
          .toList(),
      notasPreparacao: DirectionNotes(
        a: rawNotes['a'] as String?,
        b: rawNotes['b'] as String?,
        c: rawNotes['c'] as String?,
      ),
      pontosTrabalhados: d['pontosTrabalhados'] as String?,
      orientacoesRecebidas: d['orientacoesRecebidas'] as String?,
      propositosCombinados:
          rawPropositos.map((e) => e as String).toList(),
      anotacaoLivre: d['anotacaoLivre'] as String?,
    );
  }

  Map<String, dynamic> _toMap(SpiritualDirection dir) => {
        'date': Timestamp.fromDate(dir.date),
        if (dir.directorName != null) 'directorName': dir.directorName,
        if (dir.diretorContato != null) 'diretorContato': dir.diretorContato,
        if (dir.diretorParoquia != null) 'diretorParoquia': dir.diretorParoquia,
        if (dir.nextDate != null) 'nextDate': Timestamp.fromDate(dir.nextDate!),
        'questions': dir.questions
            .map((q) => {
                  'id': q.id,
                  'text': q.text,
                  'resolved': q.resolved,
                })
            .toList(),
        'notasPreparacao': {
          if (dir.notasPreparacao.a != null) 'a': dir.notasPreparacao.a,
          if (dir.notasPreparacao.b != null) 'b': dir.notasPreparacao.b,
          if (dir.notasPreparacao.c != null) 'c': dir.notasPreparacao.c,
        },
        if (dir.pontosTrabalhados != null)
          'pontosTrabalhados': dir.pontosTrabalhados,
        if (dir.orientacoesRecebidas != null)
          'orientacoesRecebidas': dir.orientacoesRecebidas,
        'propositosCombinados': dir.propositosCombinados,
        if (dir.anotacaoLivre != null) 'anotacaoLivre': dir.anotacaoLivre,
      };
}
