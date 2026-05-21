import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';

class WillTextField extends StatelessWidget {
  const WillTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
    this.prefix,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final Widget? prefix;
  final bool enabled;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: WillColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          enabled: enabled,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          cursorColor: WillColors.primary,
          style: const TextStyle(
            fontSize: 15,
            color: WillColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          inputFormatters: keyboardType == TextInputType.emailAddress
              ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: WillColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: WillColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: prefix,
            suffixIcon: suffix,
            border: _border(WillColors.border.withValues(alpha: 0.6)),
            enabledBorder: _border(WillColors.border.withValues(alpha: 0.6)),
            focusedBorder: _border(WillColors.primary.withValues(alpha: 0.9)),
            disabledBorder: _border(WillColors.border.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1),
      );
}
