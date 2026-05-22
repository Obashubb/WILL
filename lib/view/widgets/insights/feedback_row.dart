import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/insight.dart';
import '../../../services/insights_repository.dart';
import '../will_inkwell.dart';

class FeedbackRow extends StatefulWidget {
  const FeedbackRow({super.key, required this.insight});

  final Insight insight;

  @override
  State<FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<FeedbackRow> {
  bool _saved = false;

  Future<void> _record(InsightFeedbackStatus status) async {
    if (_saved) return;
    await InsightsRepository.appendFeedback(InsightFeedback(
      insightId: widget.insight.id,
      status: status,
      actedAt: DateTime.now(),
    ));
    setState(() => _saved = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: WillColors.primary,
        content: Text(
          status == InsightFeedbackStatus.helpful
              ? 'Thanks. Noted.'
              : "Thanks, we'll keep improving.",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insight.severity == InsightSeverity.calm) {
      return const SizedBox.shrink();
    }
    final alreadyGiven =
        _saved || InsightsRepository.hasFeedback(widget.insight.id);
    if (alreadyGiven) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Thanks for the feedback.',
          style: TextStyle(
            fontSize: 11,
            color: WillColors.textSecondary.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Was this right?',
            style: TextStyle(
              fontSize: 12,
              color: WillColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          _FeedbackChip(
            icon: CupertinoIcons.hand_thumbsup,
            color: WillColors.accent,
            onTap: () => _record(InsightFeedbackStatus.helpful),
          ),
          const SizedBox(width: 8),
          _FeedbackChip(
            icon: CupertinoIcons.hand_thumbsdown,
            color: WillColors.danger,
            onTap: () => _record(InsightFeedbackStatus.wrong),
          ),
        ],
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WillInkwell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
