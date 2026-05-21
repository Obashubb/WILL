import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                'Will',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: WillColors.textPrimary,
                ),
              ).animate().fadeIn(duration: 320.ms),
              const SizedBox(height: 12),
              const Text(
                'Monitor your health, simply.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: WillColors.textSecondary,
                  height: 1.25,
                  letterSpacing: 0.2,
                ),
              ).animate().fadeIn(duration: 320.ms, delay: 80.ms),
              const Spacer(flex: 3),
              WillPrimaryButton(
                label: 'Create account',
                onPressed: () => context.push(WillRoutes.signup),
              ).animate().fadeIn(duration: 240.ms, delay: 160.ms),
              const SizedBox(height: 12),
              _OutlinedAction(
                label: 'Sign in',
                onPressed: () => context.push(WillRoutes.login),
              ).animate().fadeIn(duration: 240.ms, delay: 200.ms),
              const SizedBox(height: 20),
              WillInkwell(
                onTap: () => context.push(WillRoutes.guest),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Continue as guest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: WillColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: WillColors.textSecondary,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 240.ms, delay: 240.ms),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: WillColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WillColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
