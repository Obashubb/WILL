import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController controller) async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      controller.lastError.value = 'Enter your email and password.';
      return;
    }
    final ok = await controller.signIn(_email.text, _password.text);
    if (ok && mounted) context.go(WillRoutes.deviceSetup);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const Text(
                'Welcome back.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to keep an eye on your health.',
                style: TextStyle(
                  fontSize: 14,
                  color: WillColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              WillTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (controller.lastError.value != null) {
                    controller.lastError.value = null;
                  }
                },
              ),
              const SizedBox(height: 16),
              WillTextField(
                controller: _password,
                label: 'Password',
                hint: '••••••••',
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(controller),
                onChanged: (_) {
                  if (controller.lastError.value != null) {
                    controller.lastError.value = null;
                  }
                },
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: WillColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final err = controller.lastError.value;
                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuart,
                  child: err == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            err,
                            style: const TextStyle(
                              color: WillColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ).animate().fadeIn(duration: 160.ms),
                );
              }),
              Obx(
                () => WillPrimaryButton(
                  label: 'Sign in',
                  isLoading: controller.isSubmitting.value,
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => _submit(controller),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: WillInkwell(
                  onTap: () => context.pushReplacement(WillRoutes.signup),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      'New here? Create an account',
                      style: TextStyle(
                        color: WillColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
