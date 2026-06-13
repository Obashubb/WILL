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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: WillColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}
