import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../models/user_baseline.dart';
import '../../services/profile_service.dart';
import '../widgets/will_primary_button.dart';

/// Captures the user's resting HR / SpO₂ / temp so insight narratives can
/// compare current readings against their normal. Pre-fills with sensible
/// defaults (72 bpm, 97%, 36.7°C) when no baseline is saved yet.
class BaselineSheet extends StatefulWidget {
  const BaselineSheet({super.key});

  @override
  State<BaselineSheet> createState() => _BaselineSheetState();
}

class _BaselineSheetState extends State<BaselineSheet> {
  late final TextEditingController _hr;
  late final TextEditingController _spo2;
  late final TextEditingController _temp;

  @override
  void initState() {
    super.initState();
    final current = ProfileService.readBaseline();
    _hr = TextEditingController(
      text: (current?.restingHr ?? 72).toString(),
    );
    _spo2 = TextEditingController(
      text: (current?.restingSpo2 ?? 97).toString(),
    );
    _temp = TextEditingController(
      text: (current?.restingTemp ?? 36.7).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _hr.dispose();
    _spo2.dispose();
    _temp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hr = int.tryParse(_hr.text.trim());
    final spo2 = int.tryParse(_spo2.text.trim());
    final temp = double.tryParse(_temp.text.trim());
    if (hr == null || spo2 == null || temp == null) return;
    await ProfileService.writeBaseline(UserBaseline(
      restingHr: hr.clamp(40, 130),
      restingSpo2: spo2.clamp(80, 100),
      restingTemp: temp.clamp(34.0, 39.0),
      capturedAt: DateTime.now(),
    ));
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: WillColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: Text(
                'Your resting baseline',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: WillColors.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                "Your usual numbers when you're resting and feeling well. "
                'Insights compare against these so the "why" feels personal.',
                style: TextStyle(
                  fontSize: 12,
                  color: WillColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _BaselineField(
                    label: 'Resting heart rate',
                    suffix: 'bpm',
                    controller: _hr,
                    inputType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  _BaselineField(
                    label: 'Resting oxygen',
                    suffix: '%',
                    controller: _spo2,
                    inputType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  _BaselineField(
                    label: 'Resting temperature',
                    suffix: '°C',
                    controller: _temp,
                    inputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WillPrimaryButton(
                label: 'Save baseline',
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BaselineField extends StatelessWidget {
  const _BaselineField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.inputType,
    required this.formatters,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final TextInputType inputType;
  final List<TextInputFormatter> formatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: WillColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  keyboardType: inputType,
                  inputFormatters: formatters,
                  decoration: const BoxDecoration(),
                  padding: EdgeInsets.zero,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: WillColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WillColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
