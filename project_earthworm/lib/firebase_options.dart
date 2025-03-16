// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAV4avl_i5q-XyhIezcA6EO6qfZPcd7JF0',
    appId: '1:655835623230:web:8d4a7076043351fceb866f',
    messagingSenderId: '655835623230',
    projectId: 'earthworm-2d0bd',
    authDomain: 'earthworm-2d0bd.firebaseapp.com',
    storageBucket: 'earthworm-2d0bd.firebasestorage.app',
    measurementId: 'G-GN3TXXRL9B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBRc5gv2P0Y19kRUud7zpaFZLp6Q-bqEys',
    appId: '1:655835623230:android:67ea4ceb87ecf859eb866f',
    messagingSenderId: '655835623230',
    projectId: 'earthworm-2d0bd',
    storageBucket: 'earthworm-2d0bd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCKvxPbf1idafejkoclV195XQeWf0HaonM',
    appId: '1:655835623230:ios:8dec8d76b0b494beeb866f',
    messagingSenderId: '655835623230',
    projectId: 'earthworm-2d0bd',
    storageBucket: 'earthworm-2d0bd.firebasestorage.app',
    iosBundleId: 'com.example.projectEarthworm',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCKvxPbf1idafejkoclV195XQeWf0HaonM',
    appId: '1:655835623230:ios:8dec8d76b0b494beeb866f',
    messagingSenderId: '655835623230',
    projectId: 'earthworm-2d0bd',
    storageBucket: 'earthworm-2d0bd.firebasestorage.app',
    iosBundleId: 'com.example.projectEarthworm',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAV4avl_i5q-XyhIezcA6EO6qfZPcd7JF0',
    appId: '1:655835623230:web:d3b67825ac882660eb866f',
    messagingSenderId: '655835623230',
    projectId: 'earthworm-2d0bd',
    authDomain: 'earthworm-2d0bd.firebaseapp.com',
    storageBucket: 'earthworm-2d0bd.firebasestorage.app',
    measurementId: 'G-M6FWK840ZW',
  );
}
