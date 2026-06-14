import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:healthapp/services/notification_service.dart';

import 'core/constants.dart';
import 'core/router/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/sync_service.dart';
import 'services/wearable_service.dart';
import 'services/inference_service.dart';
import 'view/auth/auth_controller.dart';

Future<void> main() async {
  // Run everything inside a guarded zone so any uncaught async error gets
  // routed to Crashlytics instead of silently dying in a logger somewhere.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      GetStorage.init(),
    ]);

    // Crashlytics: capture every Flutter framework error + any unhandled
    // platform error. In debug builds we forward to console; in release
    // they go to the Crashlytics dashboard so we can chase issues testers
    // hit on their own phones.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Analytics: instance available for screen + event tracking. The
    // router's observer is wired in WillApp below.
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);

    Get.put(AuthController(), permanent: true);
    Get.put(WearableService(), permanent: true);
    await Get.putAsync<InferenceService>(
      () => InferenceService().init(),
      permanent: true,
    );
    await Get.putAsync<NotificationService>(
      () => NotificationService().init(),
      permanent: true,
    );
    Get.put(SyncService(), permanent: true).start();
    runApp(const WillApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class WillApp extends StatelessWidget {
  const WillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: WillConstants.appName,
      theme: WillTheme.appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: WillRouter.router,
    );
  }
}
