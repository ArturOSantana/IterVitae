import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

/// Implementação Firestore do [BookRepository].
/// Caminho: /users/{uid}/books/{bookId}
class FirestoreBookRepository implements BookRepository {
  FirestoreBookRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('books');

  @override
  Future<List<Book>> getAll() async {
    final snap = await _col.orderBy('title').get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<Book>> getByStatus(BookStatus status) async {
    final snap = await _col
        .where('status', isEqualTo: status.name)
        .orderBy('title')
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> save(Book book) => _col.doc(book.id).set(_toMap(book));

  // ── Serialização ──────────────────────────────────────────────────────────

  Book _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Book(
      id: doc.id,
      title: d['title'] as String,
      author: d['author'] as String?,
      category: ReadingCategory.values.byName(d['category'] as String),
      status: BookStatus.values.byName(d['status'] as String),
      currentPage: d['currentPage'] as int? ?? 0,
      totalPages: d['totalPages'] as int? ?? 0,
      coverEmoji: d['coverEmoji'] as String? ?? '📖',
      notes: d['notes'] as String?,
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _toMap(Book b) => {
        'title': b.title,
        if (b.author != null) 'author': b.author,
        'category': b.category.name,
        'status': b.status.name,
        'currentPage': b.currentPage,
        'totalPages': b.totalPages,
        'coverEmoji': b.coverEmoji,
        if (b.notes != null) 'notes': b.notes,
        if (b.startedAt != null) 'startedAt': Timestamp.fromDate(b.startedAt!),
        if (b.finishedAt != null)
          'finishedAt': Timestamp.fromDate(b.finishedAt!),
      };
}
