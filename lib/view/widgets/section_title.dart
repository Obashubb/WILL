import 'package:flutter/material.dart';

import '../../core/colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.trailing,
    this.horizontalPadding = true,
    this.verticalPadding = true,
  });

  final String title;
  final Widget? trailing;
  final bool horizontalPadding;
  final bool verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding ? 16 : 0,
        right: horizontalPadding ? 16 : 0,
        top: verticalPadding ? 16 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: WillColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
