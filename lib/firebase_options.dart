// File generated for ReliefHub AI — shadycoders-ef442
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError('macOS is not configured — use flutterfire configure');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows is not configured — use flutterfire configure');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not configured — use flutterfire configure');
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia is not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJvWmAto1xZ4vpkn6uDG8WFOho7rRdcMc',
    appId: '1:357128336470:android:0acb1ab45e5692822437f7',
    messagingSenderId: '357128336470',
    projectId: 'shadycoders-ef442',
    storageBucket: 'shadycoders-ef442.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCAUCLCqGgrCFLuXOtkrEuFUuvVe8b-OIo',
    appId: '1:357128336470:web:8bb3424bb4ba30d82437f7',
    messagingSenderId: '357128336470',
    projectId: 'shadycoders-ef442',
    authDomain: 'shadycoders-ef442.firebaseapp.com',
    storageBucket: 'shadycoders-ef442.firebasestorage.app',
    measurementId: 'G-MHM0B1C63Y',
  );

  // iOS placeholder — configure via flutterfire configure when ready
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCJvWmAto1xZ4vpkn6uDG8WFOho7rRdcMc',
    appId: '1:357128336470:android:0acb1ab45e5692822437f7',
    messagingSenderId: '357128336470',
    projectId: 'shadycoders-ef442',
    storageBucket: 'shadycoders-ef442.firebasestorage.app',
    iosBundleId: 'com.reliefhub.ai',
  );
}
