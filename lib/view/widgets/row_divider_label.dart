import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Small uppercase section label used between blocks in long screens
/// (Insights, Care, Profile). Optionally renders a trailing widget.
class RowDividerLabel extends StatelessWidget {
  const RowDividerLabel({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WillColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
