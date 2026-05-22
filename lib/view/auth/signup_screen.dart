import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';
import '../../controllers/auth_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController controller) async {
    if (_name.text.trim().isEmpty) {
      controller.lastError.value = 'Please enter your name.';
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.length < 8) {
      controller.lastError.value =
          'Use a valid email and a password with at least 8 characters.';
      return;
    }
    final ok = await controller.signUp(
      _email.text,
      _password.text,
      name: _name.text,
    );
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
                'Create your account.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your readings stay private to you.',
                style: TextStyle(
                  fontSize: 14,
                  color: WillColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              WillTextField(
                controller: _name,
                label: 'Your name',
                hint: 'Ada',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) {
                  if (controller.lastError.value != null) {
                    controller.lastError.value = null;
                  }
                },
              ),
              const SizedBox(height: 16),
              WillTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
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
                hint: 'At least 8 characters',
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
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
              const SizedBox(height: 4),
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
                  label: 'Create account',
                  isLoading: controller.isSubmitting.value,
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => _submit(controller),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'By signing up you agree to use Will for personal monitoring only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WillColors.textSecondary,
                    fontSize: 11,
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
