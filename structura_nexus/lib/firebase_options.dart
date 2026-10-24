// File generated for Structura Nexus
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Structura Nexus Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAJlG2Ssth4ejmIJ_AJauhclsLsfoQKJjQ',
    appId: '1:413099324256:web:9e507dd5ebf577d5242405',
    messagingSenderId: '413099324256',
    projectId: 'structura-nexus',
    authDomain: 'structura-nexus.firebaseapp.com',
    storageBucket: 'structura-nexus.firebasestorage.app',
    measurementId: 'G-3HEY0TDHQX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJlG2Ssth4ejmIJ_AJauhclsLsfoQKJjQ',
    appId: '1:413099324256:android:9e507dd5ebf577d5242405',
    messagingSenderId: '413099324256',
    projectId: 'structura-nexus',
    storageBucket: 'structura-nexus.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJlG2Ssth4ejmIJ_AJauhclsLsfoQKJjQ',
    appId: '1:413099324256:ios:9e507dd5ebf577d5242405',
    messagingSenderId: '413099324256',
    projectId: 'structura-nexus',
    storageBucket: 'structura-nexus.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAJlG2Ssth4ejmIJ_AJauhclsLsfoQKJjQ',
    appId: '1:413099324256:ios:9e507dd5ebf577d5242405',
    messagingSenderId: '413099324256',
    projectId: 'structura-nexus',
    storageBucket: 'structura-nexus.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAJlG2Ssth4ejmIJ_AJauhclsLsfoQKJjQ',
    appId: '1:413099324256:web:9e507dd5ebf577d5242405',
    messagingSenderId: '413099324256',
    projectId: 'structura-nexus',
    storageBucket: 'structura-nexus.firebasestorage.app',
  );
}
