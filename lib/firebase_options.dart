import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBMRMRbnhy60KEUzMffDhYNGbkfCwEsJJI',
    appId: '1:1018262910042:web:05fb82711d0be6b7c1d463',
    messagingSenderId: '1018262910042',
    projectId: 'askula-lens',
    authDomain: 'askula-lens.firebaseapp.com',
    storageBucket: 'askula-lens.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzUcVNDLybPkMBgWqgtP6f-nWkIZ5h0eU',
    appId: '1:1018262910042:android:8a856b57973b0501c1d463',
    messagingSenderId: '1018262910042',
    projectId: 'askula-lens',
    storageBucket: 'askula-lens.firebasestorage.app',
  );
}
