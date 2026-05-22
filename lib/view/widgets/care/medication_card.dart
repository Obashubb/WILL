import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../controllers/care_controller.dart';
import '../../../core/colors.dart';
import '../../../models/medication.dart';
import '../will_inkwell.dart';
import 'dose_chip.dart';

class MedicationCard extends StatelessWidget {
  const MedicationCard({
    super.key,
    required this.med,
    required this.controller,
  });

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
                return DoseChip(
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
                              ..showSnackBar(SnackBar(
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
                              ));
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
