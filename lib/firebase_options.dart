import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Конфигурация по умолчанию для Firebase приложения
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Конфигурация для Web
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
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions не настроен для Linux - '
          'вам нужно добавить настройки вручную через flutterfire configure',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions не поддерживает указанную платформу.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAp03Rsml3jtBCUqGg6jYT_gc31A_gJOsA',
    appId: '1:839294363369:web:3d5aa387fe003c017ff278',
    messagingSenderId: '839294363369',
    projectId: 'mama-taxi-8ec61',
    authDomain: 'mama-taxi-8ec61.firebaseapp.com',
    storageBucket: 'mama-taxi-8ec61.firebasestorage.app',
    measurementId: 'G-GS9ESRLP8X',
  );

  // ВНИМАНИЕ: Эти значения нужно заменить на реальные из Firebase Console

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyByJudIAAgL0PEueRAnlgOWQb4nkXCaX-s',
    appId: '1:839294363369:android:b41285ec900467f87ff278',
    messagingSenderId: '839294363369',
    projectId: 'mama-taxi-8ec61',
    storageBucket: 'mama-taxi-8ec61.firebasestorage.app',
  );

  // ВНИМАНИЕ: Эти значения нужно заменить на реальные из Firebase Console

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgbiS0YHupclryVa1420lWEN0qTt-_5iU',
    appId: '1:839294363369:ios:a54f8a75df4dc38a7ff278',
    messagingSenderId: '839294363369',
    projectId: 'mama-taxi-8ec61',
    storageBucket: 'mama-taxi-8ec61.firebasestorage.app',
    iosBundleId: 'com.example.mamaTaxi',
  );

  // ВНИМАНИЕ: Эти значения нужно заменить на реальные из Firebase Console

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCgbiS0YHupclryVa1420lWEN0qTt-_5iU',
    appId: '1:839294363369:ios:a54f8a75df4dc38a7ff278',
    messagingSenderId: '839294363369',
    projectId: 'mama-taxi-8ec61',
    storageBucket: 'mama-taxi-8ec61.firebasestorage.app',
    iosBundleId: 'com.example.mamaTaxi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAp03Rsml3jtBCUqGg6jYT_gc31A_gJOsA',
    appId: '1:839294363369:web:5a25a8ede7714acb7ff278',
    messagingSenderId: '839294363369',
    projectId: 'mama-taxi-8ec61',
    authDomain: 'mama-taxi-8ec61.firebaseapp.com',
    storageBucket: 'mama-taxi-8ec61.firebasestorage.app',
    measurementId: 'G-KG8W0WT91P',
  );

}