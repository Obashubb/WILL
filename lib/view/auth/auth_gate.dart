import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_shell.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController(), permanent: true);
    return Obx(
      () => controller.isSignedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}
