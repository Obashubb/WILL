import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../services/demo_data_service.dart';
import '../../services/wearable_service.dart';
import '../../controllers/care_controller.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';

class DemoDataSheet extends StatefulWidget {
  const DemoDataSheet({super.key});

  @override
  State<DemoDataSheet> createState() => _DemoDataSheetState();
}

class _DemoDataSheetState extends State<DemoDataSheet> {
  bool _busy = false;
  String? _lastAction;

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _lastAction = label;
    });
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wearable = Get.find<WearableService>();
    final care = Get.find<CareController>();

    return SafeArea(
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
                'Demo data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seed the app with believable data and switch the mock generator between scenarios.',
                style: TextStyle(
                  fontSize: 13,
                  color: WillColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Scenario'),
              const SizedBox(height: 8),
              Obx(() {
                final current = wearable.mockScenario.value;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MockScenario.values.map((s) {
                    final selected = s == current;
                    return WillInkwell(
                      onTap: () => DemoDataService.setScenario(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutQuart,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? WillColors.primary
                              : WillColors.surface,
                          border: Border.all(
                            color: selected
                                ? WillColors.primary
                                : WillColors.border.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.label,
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
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'Live readings switch instantly. Wait ~30 seconds for Insights to follow.',
                style: TextStyle(
                  fontSize: 11,
                  color: WillColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Seed'),
              const SizedBox(height: 10),
              _SeedRow(
                icon: CupertinoIcons.bell,
                label: 'Sample medications',
                hint: 'Hydroxyurea, Folic acid, Paludrine.',
                onTap: _busy
                    ? null
                    : () => _run(
                          'medications',
                          () async {
                            await DemoDataService.seedMedications();
                            care.refreshAll();
                          },
                        ),
              ),
              _SeedRow(
                icon: CupertinoIcons.drop,
                label: "Today's water",
                hint: 'Five entries between 07:00 and now.',
                onTap: _busy
                    ? null
                    : () => _run(
                          'hydration',
                          () async {
                            await DemoDataService.seedHydrationDay();
                            care.refreshAll();
                          },
                        ),
              ),
              _SeedRow(
                icon: CupertinoIcons.sparkles,
                label: 'Sample insights',
                hint: 'Six Watch/Act events spread across today.',
                onTap: _busy
                    ? null
                    : () => _run(
                          'insights',
                          () async {
                            await DemoDataService.seedInsights();
                          },
                        ),
              ),
              _SeedRow(
                icon: CupertinoIcons.chart_bar,
                label: '6 hours of history',
                hint: 'Mostly normal with brief abnormal patches.',
                onTap: _busy
                    ? null
                    : () => _run(
                          'history',
                          () async {
                            await DemoDataService.seedHistory(hours: 6);
                          },
                        ),
              ),
              const SizedBox(height: 22),
              WillPrimaryButton(
                label: 'Reset all demo data',
                onPressed: _busy
                    ? null
                    : () => _run(
                          'reset',
                          () async {
                            await DemoDataService.resetAll();
                            care.refreshAll();
                          },
                        ),
              ),
              if (_lastAction != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _busy ? 'Applying $_lastAction…' : 'Done. $_lastAction applied.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: WillColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: WillColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: WillColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: WillColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: WillColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: WillColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
