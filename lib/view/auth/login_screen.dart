import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';
import 'auth_controller.dart';
import 'signup_screen.dart';

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
    await controller.signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
            children: [
              const Text(
                'Welcome back.',
                style: TextStyle(
                  fontSize: 32,
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
              const SizedBox(height: 36),
              WillTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
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
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: WillColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final err = controller.lastError.value;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    err,
                    style: const TextStyle(
                      color: WillColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(duration: 180.ms);
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
                child: TextButton(
                  onPressed: () => Get.to(() => const SignUpScreen()),
                  child: const Text(
                    'New here? Create an account',
                    style: TextStyle(
                      color: WillColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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
