import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Form widgets cap their width on tablets / large displays so a 500-pt
/// button doesn't stretch all the way across a 1024-pt iPad screen. On
/// phones the constraint is wider than the available space, so it just
/// fills like before.
const double kFormMaxWidth = 500;

class WillPrimaryButton extends StatelessWidget {
  const WillPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutQuart,
      height: 52,
      decoration: BoxDecoration(
        color: disabled
            ? WillColors.primary.withValues(alpha: 0.55)
            : WillColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      backgroundColor: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kFormMaxWidth),
        child: fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
