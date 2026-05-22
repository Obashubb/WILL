import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';
import '../../controllers/auth_controller.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final controller = Get.find<AuthController>();
    final value = _name.text.trim();
    if (value.isEmpty) {
      controller.lastError.value = 'Please enter your name.';
      return;
    }
    setState(() => _busy = true);
    await controller.continueAsGuest(value);
    if (mounted) context.go(WillRoutes.deviceSetup);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: WillColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll use this on your dashboard. You can change it later.",
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
              autofocus: true,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              onSubmitted: (_) => _continue(),
              onChanged: (_) {
                if (controller.lastError.value != null) {
                  controller.lastError.value = null;
                }
              },
            ),
            const SizedBox(height: 16),
            Obx(() {
              final err = controller.lastError.value;
              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutQuart,
                child: err == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          err,
                          style: const TextStyle(
                            color: WillColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              );
            }),
            const SizedBox(height: 12),
            WillPrimaryButton(
              label: 'Continue',
              isLoading: _busy,
              onPressed: _busy ? null : _continue,
            ),
            const SizedBox(height: 18),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Guest data stays on this phone. Create an account to back it up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WillColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
