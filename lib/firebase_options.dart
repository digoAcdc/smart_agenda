// File generated manually. Firebase apps created via: firebase apps:create
// Project: smart-agenda-a550b

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // ignore: missing_enum_constant_in_switch
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvguoAGSdz74B0Z5TaSu3TEhIVPGzL1IM',
    appId: '1:157345975923:android:fc443a65ca476792c4e406',
    messagingSenderId: '157345975923',
    projectId: 'smart-agenda-a550b',
    storageBucket: 'smart-agenda-a550b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwNXIG_heXv0KVDgh8GsIeXYl90lOFuN4',
    appId: '1:157345975923:ios:2937eb67764f47bec4e406',
    messagingSenderId: '157345975923',
    projectId: 'smart-agenda-a550b',
    storageBucket: 'smart-agenda-a550b.firebasestorage.app',
    iosBundleId: 'com.digo.smartagenda',
  );
}
