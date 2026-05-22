import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../models/user_baseline.dart';
import '../../services/profile_service.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';

class BaselineSheet extends StatefulWidget {
  const BaselineSheet({super.key});

  @override
  State<BaselineSheet> createState() => _BaselineSheetState();
}

class _BaselineSheetState extends State<BaselineSheet> {
  final _hr = TextEditingController();
  final _spo2 = TextEditingController();
  final _temp = TextEditingController();

  UserBaseline? _existing;

  // Adult averages, used when no baseline exists yet so the user has
  // something reasonable to nudge instead of an empty form.
  static const double _defaultHr = 72;
  static const double _defaultSpo2 = 97;
  static const double _defaultTemp = 36.7;

  @override
  void initState() {
    super.initState();
    _existing = ProfileService.readBaseline();
    _hr.text = (_existing?.restingHr ?? _defaultHr).toStringAsFixed(0);
    _spo2.text = (_existing?.baselineSpo2 ?? _defaultSpo2).toStringAsFixed(0);
    _temp.text = (_existing?.baselineTemp ?? _defaultTemp).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _hr.dispose();
    _spo2.dispose();
    _temp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hr = double.tryParse(_hr.text.trim()) ?? _existing?.restingHr ?? 75;
    final spo2 =
        double.tryParse(_spo2.text.trim()) ?? _existing?.baselineSpo2 ?? 97;
    final temp =
        double.tryParse(_temp.text.trim()) ?? _existing?.baselineTemp ?? 36.7;
    await ProfileService.writeBaseline(UserBaseline(
      restingHr: hr,
      baselineSpo2: spo2,
      baselineTemp: temp,
      learnedAt: DateTime.now(),
      isManual: true,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await ProfileService.clearBaseline();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final sourceText = _existing == null
        ? 'No baseline yet. The app will auto-learn one from the first calm day.'
        : _existing!.isManual
            ? 'You typed these in on ${DateFormat.yMMMd().format(_existing!.learnedAt)}.'
            : 'Auto-learned on ${DateFormat.yMMMd().format(_existing!.learnedAt)}. Typing values here marks them manual.';

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WillColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Resting baseline',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sourceText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WillColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                WillTextField(
                  controller: _hr,
                  label: 'Resting heart rate (bpm)',
                  hint: 'e.g. 72',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                WillTextField(
                  controller: _spo2,
                  label: 'Typical oxygen (%)',
                  hint: 'e.g. 97',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                WillTextField(
                  controller: _temp,
                  label: 'Typical temperature (°C)',
                  hint: 'e.g. 36.7',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 18),
                WillPrimaryButton(label: 'Save baseline', onPressed: _save),
                if (_existing != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _reset,
                      child: const Text(
                        'Clear and re-learn',
                        style: TextStyle(
                          color: WillColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
