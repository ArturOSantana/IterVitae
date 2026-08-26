import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/entities/app_user.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/practice_repository.dart';
import 'domain/repositories/struggle_repository.dart';
import 'domain/repositories/reflection_repository.dart';
import 'domain/repositories/direction_repository.dart';
import 'domain/repositories/virtue_repository.dart';
import 'domain/repositories/book_repository.dart';
import 'domain/repositories/reading_session_repository.dart';
import 'domain/repositories/diary_repository.dart';
import 'domain/repositories/exame_diario_repository.dart';
import 'domain/repositories/exame_confissao_repository.dart';
import 'domain/repositories/meio_formacao_repository.dart';
import 'data/firebase/firebase_auth_repository.dart';
import 'data/firebase/firestore_practice_repository.dart';
import 'data/firebase/firestore_struggle_repository.dart';
import 'data/firebase/firestore_reflection_repository.dart';
import 'data/firebase/firestore_direction_repository.dart';
import 'data/firebase/firestore_virtue_repository.dart';
import 'data/firebase/firestore_book_repository.dart';
import 'data/firebase/firestore_reading_session_repository.dart';
import 'data/firebase/firestore_diary_repository.dart';
import 'data/firebase/firestore_exame_diario_repository.dart';
import 'data/firebase/firestore_exame_confissao_repository.dart';
import 'data/firebase/firestore_meio_formacao_repository.dart';
import 'data/in_memory/in_memory_practice_repository.dart';
import 'data/in_memory/in_memory_struggle_repository.dart';
import 'data/in_memory/in_memory_reflection_repository.dart';
import 'data/in_memory/in_memory_direction_repository.dart';
import 'data/in_memory/in_memory_virtue_repository.dart';
import 'data/in_memory/in_memory_book_repository.dart';
import 'data/in_memory/in_memory_reading_session_repository.dart';
import 'data/in_memory/in_memory_diary_repository.dart';
import 'data/in_memory/in_memory_exame_diario_repository.dart';
import 'data/in_memory/in_memory_exame_confissao_repository.dart';
import 'data/in_memory/in_memory_meio_formacao_repository.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

/// Repositório de autenticação — sempre Firebase.
final authRepositoryProvider = Provider<AuthRepository>(
  (_) => FirebaseAuthRepository(),
);

/// Usuário atual (null quando deslogado).
/// Observa o stream do repositório para que providers derivados
/// sejam invalidados automaticamente ao fazer login/logout.
final currentUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.read(authRepositoryProvider).userStream,
);

// ── Repositórios de domínio ───────────────────────────────────────────────────
//
// Quando [currentUserProvider] retorna um usuário autenticado, usa Firestore.
// Enquanto não há usuário (app a frio, antes do login), cai no in-memory
// para não lançar exceção.
//
// A troca é automática: quando o usuário faz login, os providers são
// invalidados e recriados com a implementação Firestore.

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final uid = userAsync.valueOrNull?.uid;
  if (uid != null) return FirestorePracticeRepository(uid: uid);
  return InMemoryPracticeRepository();
});

final struggleRepositoryProvider = Provider<StruggleRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreStruggleRepository(uid: uid);
  return InMemoryStruggleRepository();
});

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreReflectionRepository(uid: uid);
  return InMemoryReflectionRepository();
});

final directionRepositoryProvider = Provider<DirectionRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreDirectionRepository(uid: uid);
  return InMemoryDirectionRepository();
});

final virtueRepositoryProvider = Provider<VirtueRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreVirtueRepository(uid: uid);
  return InMemoryVirtueRepository();
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreBookRepository(uid: uid);
  return InMemoryBookRepository();
});

final readingSessionRepositoryProvider = Provider<ReadingSessionRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreReadingSessionRepository(uid: uid);
  return InMemoryReadingSessionRepository();
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreDiaryRepository(uid: uid);
  return InMemoryDiaryRepository();
});

final exameDiarioRepositoryProvider = Provider<ExameDiarioRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreExameDiarioRepository(uid: uid);
  return InMemoryExameDiarioRepository();
});

final exameConfissaoRepositoryProvider = Provider<ExameConfissaoRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreExameConfissaoRepository(uid: uid);
  return InMemoryExameConfissaoRepository();
});

final meioFormacaoRepositoryProvider = Provider<MeioFormacaoRepository>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid != null) return FirestoreMeioFormacaoRepository(uid: uid);
  return InMemoryMeioFormacaoRepository();
});
