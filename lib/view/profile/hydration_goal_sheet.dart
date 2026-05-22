import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../care/care_controller.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';

const _presets = <int>[1500, 2000, 2500, 3000];

class HydrationGoalSheet extends StatefulWidget {
  const HydrationGoalSheet({super.key});

  @override
  State<HydrationGoalSheet> createState() => _HydrationGoalSheetState();
}

class _HydrationGoalSheetState extends State<HydrationGoalSheet> {
  late int _value;
  final _custom = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = Get.find<CareController>().hydrationGoalMl.value;
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final care = Get.find<CareController>();
    final parsed = int.tryParse(_custom.text.trim());
    final next = (parsed != null && parsed > 0) ? parsed : _value;
    await care.setHydrationGoal(next);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                'Hydration goal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Daily target. Most adults aim for 2-2.5 litres.',
                style: TextStyle(
                  fontSize: 13,
                  color: WillColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((ml) {
                  final selected = ml == _value;
                  return WillInkwell(
                    onTap: () {
                      setState(() {
                        _value = ml;
                        _custom.clear();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutQuart,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? WillColors.primary : WillColors.surface,
                        border: Border.all(
                          color: selected
                              ? WillColors.primary
                              : WillColors.border.withValues(alpha: 0.6),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$ml ml',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : WillColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              WillTextField(
                controller: _custom,
                label: 'Custom (ml)',
                hint: 'e.g. 2200',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 18),
              WillPrimaryButton(
                label: 'Save goal',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
