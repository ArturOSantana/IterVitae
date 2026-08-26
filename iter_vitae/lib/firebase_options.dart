// File generated manually from google-services.json / GoogleService-Info.plist.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-ZUdd33Uo2fVOJYjKQlzAJSOmejqliGk',
    appId: '1:1027556531078:android:0e6e0dbcaca5c380556a07',
    messagingSenderId: '1027556531078',
    projectId: 'itevitae-b9b87',
    storageBucket: 'itevitae-b9b87.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-ZUdd33Uo2fVOJYjKQlzAJSOmejqliGk',
    appId: '1:1027556531078:ios:0c49ec073f350401556a07',
    messagingSenderId: '1027556531078',
    projectId: 'itevitae-b9b87',
    storageBucket: 'itevitae-b9b87.firebasestorage.app',
    iosClientId: '1027556531078-r23hnpmplm6u6i25rd4he3biv1scltn3.apps.googleusercontent.com',
    iosBundleId: 'com.itervitae.iterVitae',
  );
}
