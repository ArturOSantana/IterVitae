const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function — Parte 4
 *
 * Dispara um push real via FCM sempre que o diretor escreve uma notificação
 * pontual em /users/{directeeUid}/notifications_from_director/{notifId}.
 *
 * O token FCM do dirigido deve existir em /users/{directeeUid}/fcmToken
 * (campo gravado pelo app principal ao inicializar o FirebaseMessaging).
 */
exports.onDirectorNotificationCreated = functions.firestore
  .document('users/{directeeUid}/notifications_from_director/{notifId}')
  .onCreate(async (snap, context) {
    const { directeeUid } = context.params;
    const data = snap.data();

    if (!data || !data.texto) {
      console.warn('Notificação sem texto — ignorada.', { directeeUid });
      return null;
    }

    // Busca o token FCM do dirigido
    const userDoc = await admin
      .firestore()
      .collection('users')
      .doc(directeeUid)
      .get();

    const fcmToken = userDoc.get('fcmToken');
    if (!fcmToken) {
      console.warn('Dirigido sem token FCM — push não enviado.', {
        directeeUid,
      });
      return null;
    }

    // Busca o nome do diretor para personalizar a notificação
    let directorLabel = 'Seu diretor espiritual';
    if (data.directorUid) {
      const directorDoc = await admin
        .firestore()
        .collection('directors')
        .doc(data.directorUid)
        .get();
      const nome = directorDoc.get('nome');
      if (nome) directorLabel = nome;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: directorLabel,
        body: data.texto,
      },
      data: {
        // Abre a tela de Direção ao tocar na notificação
        route: '/direcao',
        notifId: snap.id,
      },
      android: {
        priority: 'normal',
        notification: {
          channelId: 'director_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.info('Push enviado com sucesso.', { response, directeeUid });
    } catch (err) {
      // Não propaga o erro — a notificação já está salva no Firestore;
      // o dirigido verá ao abrir o app mesmo sem o push.
      console.error('Erro ao enviar push.', {
        directeeUid,
        error: err.message,
      });
    }

    return null;
  });

/**
 * Cloud Function — Parte 5
 *
 * Dispara um push informando ao diretor que um relatório foi enviado.
 * Caminho: /directors/{directorUid}/directees/{directeeUid}/reports/{reportId}
 *
 * O token FCM do diretor deve existir em /directors/{directorUid}/fcmToken.
 */
exports.onReportSent = functions.firestore
  .document(
    'directors/{directorUid}/directees/{directeeUid}/reports/{reportId}'
  )
  .onCreate(async (snap, context) => {
    const { directorUid, directeeUid } = context.params;

    // Busca apelido do dirigido
    const directeeDoc = await admin
      .firestore()
      .collection('directors')
      .doc(directorUid)
      .collection('directees')
      .doc(directeeUid)
      .get();

    const apelido = directeeDoc.get('apelido') ?? 'Um dirigido';

    // Busca token FCM do diretor
    const directorDoc = await admin
      .firestore()
      .collection('directors')
      .doc(directorUid)
      .get();

    const fcmToken = directorDoc.get('fcmToken');
    if (!fcmToken) {
      console.warn('Diretor sem token FCM.', { directorUid });
      return null;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: 'Novo relatório recebido',
        body: `${apelido} enviou um relatório de preparação.`,
      },
      data: {
        route: '/dirigidos',
        directeeUid,
      },
    };

    try {
      await admin.messaging().send(message);
    } catch (err) {
      console.error('Erro ao enviar push de relatório.', {
        directorUid,
        error: err.message,
      });
    }

    return null;
  });
