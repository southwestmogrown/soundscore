import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Lock to portrait for v1
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final config = AppConfig.instance;

      // Firebase (skip if no google-services.json / GoogleService-Info.plist yet)
      try {
        await Firebase.initializeApp();
        if (config.enableCrashlytics) {
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        }
      } catch (e) {
        // Firebase not configured yet — safe to ignore during development
        debugPrint('Firebase initialization skipped: $e');
      }

      runApp(SoundScoreApp());
    },
    (error, stack) {
      if (AppConfig.hasInstance && AppConfig.instance.enableCrashlytics) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Uncaught error: $error\n$stack');
      }
    },
  );
}
