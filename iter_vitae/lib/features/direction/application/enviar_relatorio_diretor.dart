import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';

/// Estado do envio de relatório ao diretor.
class EnviarRelatorioDiretorState {
  const EnviarRelatorioDiretorState({
    this.isUploading = false,
    this.enviado = false,
    this.erro,
  });

  final bool isUploading;
  final bool enviado;
  final String? erro;
}

/// Envia o PDF do relatório ao diretor vinculado.
///
/// Fluxo:
/// 1. Faz upload para Storage em reports/{directorUid}/{directeeUid}/{reportId}
/// 2. Grava a referência em /directors/{directorUid}/directees/{directeeUid}/reports/{reportId}
/// 3. A Cloud Function `onReportSent` dispara push ao diretor automaticamente.
class EnviarRelatorioDiretorController
    extends AsyncNotifier<EnviarRelatorioDiretorState> {
  @override
  Future<EnviarRelatorioDiretorState> build() async =>
      const EnviarRelatorioDiretorState();

  Future<void> enviar({
    required Uint8List pdfBytes,
    required String nomeArquivo,
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    // Busca o directorUid do usuário
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final directorUid = userDoc.data()?['directorUid'] as String?;

    if (directorUid == null || directorUid.isEmpty) {
      state = const AsyncData(EnviarRelatorioDiretorState(
        erro: 'Você ainda não está vinculado a um diretor.',
      ));
      return;
    }

    state = const AsyncData(EnviarRelatorioDiretorState(isUploading: true));

    try {
      final reportId = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath =
          'reports/$directorUid/${user.uid}/$reportId.pdf';

      // 1. Upload para o Storage
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putData(
        pdfBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final downloadUrl = await ref.getDownloadURL();

      // 2. Grava referência no Firestore
      await FirebaseFirestore.instance
          .collection('directors')
          .doc(directorUid)
          .collection('directees')
          .doc(user.uid)
          .collection('reports')
          .doc(reportId)
          .set({
        'nomeArquivo': nomeArquivo,
        'storageUrl': downloadUrl,
        'storagePath': storagePath,
        'enviadoEm': FieldValue.serverTimestamp(),
        'directeeUid': user.uid,
      });

      state = const AsyncData(EnviarRelatorioDiretorState(enviado: true));
    } catch (_) {
      state = const AsyncData(EnviarRelatorioDiretorState(
        erro: 'Erro ao enviar. Tente novamente.',
      ));
    }
  }
}

final enviarRelatorioDiretorProvider = AsyncNotifierProvider<
    EnviarRelatorioDiretorController, EnviarRelatorioDiretorState>(
  EnviarRelatorioDiretorController.new,
);

/// Provider que indica se o usuário tem um diretor vinculado.
/// Usa snapshots em tempo real para reagir ao desvínculo feito pelo diretor.
final temDiretorVinculadoProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid));
  if (uid == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
        final directorUid = snap.data()?['directorUid'] as String?;
        return directorUid != null && directorUid.isNotEmpty;
      });
});
