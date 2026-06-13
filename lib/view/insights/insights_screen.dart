import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../services/inference_service.dart';
import '../../services/wearable_service.dart';
import '../widgets/section_title.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool? _feedback;
  InsightResult? _ratedInsight; // which insight the feedback was for

  Future<void> _saveFeedback(InsightLabel label, bool helpful) async {
    setState(() {
      _feedback = helpful;
      _ratedInsight = Get.find<WearableService>().currentInsight.value;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('insights')
        .add({
          'label': label.name,
          'helpful': helpful,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wearable = Get.find<WearableService>();
    final inference = Get.find<InferenceService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SectionTitle('Insights'),
        Expanded(
          child: Obx(() {
            final result = wearable.currentInsight.value;
            if (_ratedInsight != null && _ratedInsight != result) {
              _feedback = null;
              _ratedInsight = null;
            }
            final label = result.severity;
            final condition = result.condition;
            final message = inference.messageFor(label);
            final sample = wearable.latestSample.value;
            if (sample == null) {
              return const Center(
                child: Text(
                  'Waiting for readings from your band.',
                  style: TextStyle(
                    color: WillColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _StatusCard(label: label, message: message),
                const SizedBox(height: 24),
                // The detected condition — the emphasis of the project.
                if (condition != ConditionLabel.none) ...[
                  _ConditionCard(
                    condition: condition,
                    message: inference.conditionMessage(condition),
                  ),
                  const SizedBox(height: 24),
                ],
                _WhySection(reasons: _buildReasons(sample, label)),
                const SizedBox(height: 24),
                _FeedbackRow(
                  feedback: _feedback,
                  onTap: (helpful) => _saveFeedback(label, helpful),
                ),
                const SizedBox(height: 32),
                _ReadingsSummary(sample: sample),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.message});

  final InsightLabel label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(label);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: spec.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, color: spec.color, size: 20),
              const SizedBox(width: 8),
              Text(
                spec.title,
                style: TextStyle(
                  color: spec.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: WillColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, IconData icon, String title}) _specFor(InsightLabel l) {
    switch (l) {
      case InsightLabel.normal:
        return (
          color: WillColors.accent,
          icon: CupertinoIcons.checkmark_circle_fill,
          title: 'All clear',
        );
      case InsightLabel.watch:
        return (
          color: WillColors.warning,
          icon: CupertinoIcons.exclamationmark_circle_fill,
          title: 'Watch',
        );
      case InsightLabel.alert:
        return (
          color: WillColors.danger,
          icon: CupertinoIcons.xmark_circle_fill,
          title: 'Alert',
        );
    }
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.condition, required this.message});

  final ConditionLabel condition;
  final String message;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(condition);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: spec.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(spec.icon, color: spec.color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                spec.title,
                style: TextStyle(
                  color: spec.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: WillColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, IconData icon, String title}) _specFor(ConditionLabel c) {
    switch (c) {
      case ConditionLabel.none:
        return (
          color: WillColors.accent,
          icon: CupertinoIcons.checkmark_circle,
          title: 'No condition',
        );
      case ConditionLabel.stress:
        return (
          color: const Color(0xFFE0A458), // warm amber
          icon: CupertinoIcons.bolt_fill,
          title: 'Stress',
        );
      case ConditionLabel.dehydration:
        return (
          color: const Color(0xFF5B8DEF), // slate blue
          icon: CupertinoIcons.drop_fill,
          title: 'Dehydration',
        );
      case ConditionLabel.overexertion:
        return (
          color: const Color(0xFF14B8A6), // teal
          icon: CupertinoIcons.flame_fill,
          title: 'Overexertion',
        );
    }
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.feedback, required this.onTap});

  final bool? feedback;
  final void Function(bool helpful) onTap;

  @override
  Widget build(BuildContext context) {
    // Once rated, collapse to a small thank-you line.
    if (feedback != null) {
      return const Text(
        'Thanks, noted.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: WillColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Was this insight accurate?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: WillColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FeedbackButton(
              icon: CupertinoIcons.hand_thumbsup_fill,
              label: 'Yes',
              selected: false,
              color: WillColors.accent,
              onTap: () => onTap(true),
            ),
            const SizedBox(width: 12),
            _FeedbackButton(
              icon: CupertinoIcons.hand_thumbsdown_fill,
              label: 'No',
              selected: false,
              color: WillColors.danger,
              onTap: () => onTap(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : WillColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : WillColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? color : WillColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : WillColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingsSummary extends StatelessWidget {
  const _ReadingsSummary({required this.sample});

  final sample;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Based on',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: WillColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _Row(label: 'Heart rate', value: '${sample.heartRate} bpm'),
        _Row(label: 'Oxygen', value: '${sample.spo2}%'),
        _Row(label: 'Temperature', value: '${sample.temperature}°C'),
        _Row(label: 'Motion', value: '${sample.motion}'),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: WillColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WillColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One explanation line: what the reading is, and whether it's a concern.
class _Reason {
  final String text;
  final bool isConcern; // true = outside normal, false = reassuring
  const _Reason(this.text, this.isConcern);
}

/// Builds the "what this means" explanation. Crucially, it respects the
/// model's verdict: if the model says Normal, we never show a concern —
/// the explanation explains the model's decision rather than running its
/// own separate judgment. Only when the model says Watch or Alert do we
/// surface which specific vitals are outside their normal range.
List<_Reason> _buildReasons(dynamic s, InsightLabel label) {
  // Model says everything's fine — show only reassurance, no contradictions.
  if (label == InsightLabel.normal) {
    return const [
      _Reason('All your vitals are within their normal ranges.', false),
    ];
  }

  final reasons = <_Reason>[];

  final hr = s.heartRate as int;
  if (hr > 100) {
    reasons.add(
      _Reason(
        'Your heart rate is $hr bpm, above the normal range of 75–100 bpm.',
        true,
      ),
    );
  } else if (hr < 75) {
    reasons.add(
      _Reason(
        'Your heart rate is $hr bpm, below the normal range of 75–100 bpm.',
        true,
      ),
    );
  }

  final spo2 = s.spo2 as int;
  if (spo2 < 92) {
    reasons.add(
      _Reason(
        'Your oxygen is $spo2%, below the normal range of 92–100%.',
        true,
      ),
    );
  }

  final temp = s.temperature as double;
  if (temp >= 37.8) {
    reasons.add(
      _Reason(
        'Your temperature is ${temp.toStringAsFixed(1)}°C, which is raised.',
        true,
      ),
    );
  } else if (temp < 36.0) {
    reasons.add(
      _Reason(
        'Your temperature is ${temp.toStringAsFixed(1)}°C, which is low.',
        true,
      ),
    );
  }

  final motion = s.motion as double;
  if (motion > 0.6) {
    reasons.add(
      _Reason('Your activity level is high, which can be a strain.', true),
    );
  }

  // The model flagged something but no single vital crossed our simple
  // thresholds — the model saw a combined pattern. Give a general line.
  if (reasons.isEmpty) {
    reasons.add(
      _Reason(
        'Your readings together suggest you should keep an eye on how you feel.',
        true,
      ),
    );
  }

  return reasons;
}

class _WhySection extends StatelessWidget {
  const _WhySection({required this.reasons});

  final List<_Reason> reasons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What this means',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: WillColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...reasons.map((r) {
          final tint = r.isConcern ? WillColors.warning : WillColors.accent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    r.isConcern
                        ? CupertinoIcons.exclamationmark
                        : CupertinoIcons.checkmark,
                    size: 15,
                    color: tint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: WillColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
