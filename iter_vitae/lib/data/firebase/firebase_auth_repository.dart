import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementação Firebase do [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  Stream<AppUser?> get userStream =>
      _auth.authStateChanges().map(_fromFirebase);

  @override
  AppUser? get currentUser => _fromFirebase(_auth.currentUser);

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(cred.user);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final cred = await _auth.signInWithPopup(provider);
      return _requireUser(cred.user);
    }

    final account = await _google.signIn();
    if (account == null) throw const _SignInCancelledException();

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _requireUser(cred.user);
  }

  @override
  Future<AppUser> createAccountWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(cred.user);
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) await _google.signOut();
    await _auth.signOut();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  AppUser? _fromFirebase(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  AppUser _requireUser(User? user) {
    if (user == null) throw const _NoUserException();
    return _fromFirebase(user)!;
  }
}

class _SignInCancelledException implements Exception {
  const _SignInCancelledException();
  @override
  String toString() => 'Login com Google cancelado pelo usuário.';
}

class _NoUserException implements Exception {
  const _NoUserException();
  @override
  String toString() => 'Nenhum usuário retornado pela autenticação.';
}
