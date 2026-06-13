import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../models/medications.dart';
import '../widgets/section_title.dart';
import 'care_controller.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Create the controller once for this screen.
  final CareController c = Get.put(CareController());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Care'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _HydrationCard(c: c),
              const SizedBox(height: 28),
              _MedicationsHeader(c: c),
              const SizedBox(height: 12),
              _MedicationsList(c: c),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hydration ──────────────────────────────────────────────────────────────────

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({required this.c});
  final CareController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = c.todayWaterMl.value;
      final goal = c.goalMl.value;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: WillColors.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s water',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: WillColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _editGoal(context),
                  child: Text(
                    'Goal: ${(goal / 1000).toStringAsFixed(1)} L',
                    style: const TextStyle(
                      fontSize: 12,
                      color: WillColors.action,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: c.progress,
                minHeight: 10,
                backgroundColor: WillColors.textSecondary.withValues(
                  alpha: 0.12,
                ),
                valueColor: const AlwaysStoppedAnimation(WillColors.action),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$total ml of $goal ml',
              style: const TextStyle(
                fontSize: 13,
                color: WillColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _AddButton(label: '+250 ml', onTap: () => c.addWater(250)),
                const SizedBox(width: 12),
                _AddButton(label: '+500 ml', onTap: () => c.addWater(500)),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _editGoal(BuildContext context) {
    final controller = TextEditingController(
      text: (c.goalMl.value / 1000).toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Daily water goal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'litres'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final litres = double.tryParse(controller.text);
              if (litres != null && litres > 0) {
                c.updateGoal((litres * 1000).round());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WillColors.action.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: WillColors.action,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Medications ─────────────────────────────────────────────────────────────────

class _MedicationsHeader extends StatelessWidget {
  const _MedicationsHeader({required this.c});
  final CareController c;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Medications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: WillColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => _addMedication(context, c),
          child: Row(
            children: const [
              Icon(CupertinoIcons.add, size: 16, color: WillColors.action),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: WillColors.action,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicationsList extends StatelessWidget {
  const _MedicationsList({required this.c});
  final CareController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meds = c.medications;
      if (meds.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          alignment: Alignment.center,
          child: const Text(
            'No medications added yet.',
            style: TextStyle(color: WillColors.textSecondary, fontSize: 13),
          ),
        );
      }
      return Column(
        children: meds.map((m) => _MedicationTile(c: c, med: m)).toList(),
      );
    });
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.c, required this.med});
  final CareController c;
  final Medications med;

  @override
  Widget build(BuildContext context) {
    final taken = med.takenToday;
    final timeLabel =
        '${med.hour.toString().padLeft(2, '0')}:${med.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: WillColors.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.dose} · $timeLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: taken ? null : () => c.markTaken(med),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: taken
                    ? WillColors.accent.withValues(alpha: 0.12)
                    : WillColors.action.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                taken ? 'Taken' : 'Mark taken',
                style: TextStyle(
                  color: taken ? WillColors.accent : WillColors.action,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => c.deleteMedication(med),
            child: const Icon(
              CupertinoIcons.delete,
              size: 18,
              color: WillColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Add-medication dialog — collects name, dose, and time.
void _addMedication(BuildContext context, CareController c) {
  final nameController = TextEditingController();
  final doseController = TextEditingController();
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: doseController,
              decoration: const InputDecoration(labelText: 'Dose (e.g. 5mg)'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time'),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() => selectedTime = picked);
                    }
                  },
                  child: Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              final med = Medications(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                dose: doseController.text.trim(),
                hour: selectedTime.hour,
                minute: selectedTime.minute,
              );
              c.addMedication(med);
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
