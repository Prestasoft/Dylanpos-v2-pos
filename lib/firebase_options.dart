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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
      // SANTO DOMINGO ESTE BASE DE DATOS (ACTIVO)
      apiKey: "AIzaSyDfcwhEq_JuUg23OonfQtYtDGzlXQEXI9c",
      authDomain: "sistema-victor-sde.firebaseapp.com",
      databaseURL: "https://sistema-victor-sde-default-rtdb.firebaseio.com",
      projectId: "sistema-victor-sde",
      storageBucket: "sistema-victor-sde.firebasestorage.app",
      messagingSenderId: "180650620806",
      appId: "1:180650620806:web:5daf2c0d43927db6a61e07",
      measurementId: "G-231GYNFL54"
      );

  // SANTIAGO BASE DE DATOS
  //   apiKey: "AIzaSyBP1pN3CBRNcUROMYinjTjKCzisLN7RjA0",
  // authDomain: "dylanpos-v2.firebaseapp.com",
  // databaseURL: "https://dylanpos-v2-default-rtdb.firebaseio.com",
  // projectId: "dylanpos-v2",
  // storageBucket: "dylanpos-v2.firebasestorage.app",
  // messagingSenderId: "917502791038",
  // appId: "1:917502791038:web:478334d1eb2748c1c6772f",
  // measurementId: "G-XN9YDWN22N"

  // SANTO DOMINGO BASE DE DATOS
  // apiKey: "AIzaSyCm5cqfIUlV3wll49QA36IRwUrbnww__lo",
  // authDomain: "dylanpos-victorfoto-stodgo.firebaseapp.com",
  // databaseURL: "https://dylanpos-victorfoto-stodgo-default-rtdb.firebaseio.com",
  // projectId: "dylanpos-victorfoto-stodgo",
  // storageBucket: "dylanpos-victorfoto-stodgo.firebasestorage.app",
  // messagingSenderId: "892139987413",
  // appId: "1:892139987413:web:e93a15d7a74313c78e1d5c",
  // measurementId: "G-B6GB7L2RCM"

  // LA ROMANA BASE DE DATOS
  // apiKey: "AIzaSyBkEcFoUDjFXH8IcH-oxlWHNZ_H15WfEE0",
  // authDomain: "sistema-victor-romana.firebaseapp.com",
  // databaseURL: "https://sistema-victor-romana-default-rtdb.firebaseio.com",
  // projectId: "sistema-victor-romana",
  // storageBucket: "sistema-victor-romana.firebasestorage.app",
  // messagingSenderId: "609430938517",
  // appId: "1:609430938517:web:fbc73dda27c7fee4974c9c",
  // measurementId: "G-KHTR23Q0FM"
}
