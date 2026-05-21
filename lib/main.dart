import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/constants.dart';
import 'core/router/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/sync_service.dart';
import 'services/wearable_service.dart';
import 'view/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    GetStorage.init(),
  ]);
  Get.put(AuthController(), permanent: true);
  Get.put(WearableService(), permanent: true);
  Get.put(SyncService(), permanent: true).start();
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
