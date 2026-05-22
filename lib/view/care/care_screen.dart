import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../models/medication.dart';
import '../widgets/section_title.dart';
import '../widgets/will_inkwell.dart';
import 'add_medication_sheet.dart';
import 'care_controller.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen>
    with AutomaticKeepAliveClientMixin {
  late final CareController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller =
        Get.isRegistered<CareController>() ? Get.find() : Get.put(CareController());
  }

  void _openAddMedication() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WillColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddMedicationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final meds = controller.medications;
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const SectionTitle('Care'),
          const SizedBox(height: 16),
          _HydrationBlock(controller: controller),
          const SizedBox(height: 28),
          _RowDivider(
            label: 'Medications',
            trailing: WillInkwell(
              onTap: _openAddMedication,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.add_circled,
                    size: 16,
                    color: WillColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WillColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (meds.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                'No medications yet. Tap Add to start tracking one.',
                style: TextStyle(
                  fontSize: 13,
                  color: WillColors.textSecondary,
                ),
              ),
            )
          else
            ...meds.map((m) => _MedicationCard(med: m, controller: controller)),
        ],
      );
    });
  }
}

class _HydrationBlock extends StatelessWidget {
  const _HydrationBlock({required this.controller});

  final CareController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HydrationRing(controller: controller),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hydration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HydrationButton(
                      label: '+250 ml',
                      onTap: () => controller.addHydration(250),
                    ),
                    const SizedBox(width: 8),
                    _HydrationButton(
                      label: '+500 ml',
                      onTap: () => controller.addHydration(500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  controller.hydrationToday.isEmpty
                      ? 'No water logged yet today.'
                      : '${controller.hydrationToday.length} entry${controller.hydrationToday.length == 1 ? '' : ' (s)'} today',
                  style: const TextStyle(
                    fontSize: 12,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationRing extends StatelessWidget {
  const _HydrationRing({required this.controller});

  final CareController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.hydrationProgress;
    final total = controller.hydrationTotalMl;
    final goal = controller.hydrationGoalMl.value;
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 9,
              valueColor: AlwaysStoppedAnimation<Color>(
                WillColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 124,
            height: 124,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuart,
              builder: (_, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                strokeCap: StrokeCap.round,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(WillColors.action),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of $goal ml',
                style: const TextStyle(
                  fontSize: 11,
                  color: WillColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HydrationButton extends StatelessWidget {
  const _HydrationButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WillColors.action.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WillColors.action.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WillColors.action,
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.med, required this.controller});

  final Medication med;
  final CareController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: WillColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        med.dose,
                        style: const TextStyle(
                          fontSize: 13,
                          color: WillColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                WillInkwell(
                  onTap: () => controller.deleteMedication(med.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: WillColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: med.times.map((t) {
                final logged = controller.doseLoggedFor(med, t);
                return _DoseChip(
                  time: t.format(context),
                  taken: logged,
                  onTap: logged
                      ? null
                      : () async {
                          await controller.logDose(
                            med: med,
                            scheduledTime: t,
                            status: MedicationLogStatus.taken,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: WillColors.primary,
                                  content: Text(
                                    '${med.name} marked taken.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                          }
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseChip extends StatelessWidget {
  const _DoseChip({
    required this.time,
    required this.taken,
    required this.onTap,
  });

  final String time;
  final bool taken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = taken ? WillColors.accent : WillColors.textSecondary;
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              taken ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clock,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.label, this.trailing});

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
