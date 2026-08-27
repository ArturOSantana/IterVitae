import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Implementação Firestore do [UserProfileRepository].
/// Os dados são persistidos no documento /users/{uid} sob a chave 'profile'.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(uid);

  @override
  Future<UserProfile?> get() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final profile = data['profile'] as Map<String, dynamic>?;
    if (profile == null) return null;
    return UserProfile(
      nome: profile['nome'] as String?,
      telefone: profile['telefone'] as String?,
      paroquia: profile['paroquia'] as String?,
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _doc.set(
      {
        'profile': {
          if (profile.nome != null) 'nome': profile.nome,
          if (profile.telefone != null) 'telefone': profile.telefone,
          if (profile.paroquia != null) 'paroquia': profile.paroquia,
        },
      },
      SetOptions(merge: true),
    );
  }
}
