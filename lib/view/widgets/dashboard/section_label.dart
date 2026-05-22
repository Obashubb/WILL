import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: WillColors.textPrimary,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 11,
            color: WillColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
