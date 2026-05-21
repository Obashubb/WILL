import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'view/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    GetStorage.init(),
  ]);
  runApp(const WillApp());
}

class WillApp extends StatelessWidget {
  const WillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: WillConstants.appName,
      theme: WillTheme.appTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
