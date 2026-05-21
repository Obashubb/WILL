import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/colors.dart';
import '../core/router/routes.dart';
import 'widgets/will_primary_button.dart';

enum ErrorType { notFound, generic, network }

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.type = ErrorType.generic});

  final ErrorType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icon,
                size: 56,
                color: WillColors.textSecondary.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 18),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: WillColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: WillPrimaryButton(
                  label: 'Take me home',
                  onPressed: () => context.go(WillRoutes.home),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (type) {
      case ErrorType.notFound:
        return CupertinoIcons.compass;
      case ErrorType.network:
        return CupertinoIcons.wifi_slash;
      case ErrorType.generic:
        return CupertinoIcons.exclamationmark_triangle;
    }
  }

  String get _title {
    switch (type) {
      case ErrorType.notFound:
        return "We can't find that page.";
      case ErrorType.network:
        return 'No internet connection.';
      case ErrorType.generic:
        return 'Something went wrong.';
    }
  }

  String get _subtitle {
    switch (type) {
      case ErrorType.notFound:
        return 'It might have moved, or never existed.';
      case ErrorType.network:
        return 'Reconnect and try again.';
      case ErrorType.generic:
        return 'Try again in a moment.';
    }
  }
}
