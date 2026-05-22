import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/constants.dart';
import 'core/router/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/inference_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'services/wearable_service.dart';
import 'view/auth/auth_controller.dart';
import 'view/care/care_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage must be ready before any controller can read from it.
  await GetStorage.init();

  // Firebase and notifications can fail in some environments (offline
  // emulator, missing entitlements). They are not catastrophic — the rest
  // of the app still works with what's on disk.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  try {
    await NotificationService.init();
  } catch (_) {}

  Get.put(AuthController(), permanent: true);
  Get.put(WearableService(), permanent: true);
  Get.put(InferenceService(), permanent: true);
  Get.put(SyncService(), permanent: true).start();
  Get.put(CareController(), permanent: true);
  runApp(const WillApp());
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
