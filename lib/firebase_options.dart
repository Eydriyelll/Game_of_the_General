// lib/firebase_options.dart
// ⚠️  Replace these values with your own Firebase project config.
// Go to: https://console.firebase.google.com → Your Project → Project Settings → Web App

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // 🔧 REPLACE THESE WITH YOUR FIREBASE CONFIG
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDV81uaoEsQwvm_dZC2zJMgoSwwVo1hSds',
    appId: '1:1089117576328:web:bfe9884b71052cc876d33d',
    messagingSenderId: '1089117576328',
    projectId: 'games-ecf5e',
    databaseURL:
        'https://games-ecf5e-default-rtdb.asia-southeast1.firebasedatabase.app', // e.g. https://your-project-default-rtdb.firebaseio.com
    storageBucket: 'games-ecf5e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDV81uaoEsQwvm_dZC2zJMgoSwwVo1hSds',
    appId: '1:1089117576328:android:7c9c9c9c9c9c9c9c9c9c9c',
    messagingSenderId: '1089117576328',
    projectId: 'games-ecf5e',
    databaseURL:
        'https://games-ecf5e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'games-ecf5e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDV81uaoEsQwvm_dZC2zJMgoSwwVo1hSds',
    appId: '1:1089117576328:ios:7c9c9c9c9c9c9c9c9c9c9c',
    messagingSenderId: '1089117576328',
    projectId: 'games-ecf5e',
    databaseURL:
        'https://games-ecf5e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'games-ecf5e.firebasestorage.app',
  );
}
