import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web; // 目前只部署 web
      default:
        throw UnsupportedError('此平台尚未設定 Firebase');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChKg3BlsgsLPo7OlYC4D3JlnrDmMPzygU',
    authDomain: 'focusstone-38201.firebaseapp.com',
    projectId: 'focusstone-38201',
    storageBucket: 'focusstone-38201.firebasestorage.app',
    messagingSenderId: '999739666866',
    appId: '1:999739666866:web:d8d1b61a4cff90ecf934ab',
    measurementId: 'G-XRVD37ZDRP',
  );
}
