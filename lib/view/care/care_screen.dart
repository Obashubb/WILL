import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/care_controller.dart';
import '../../core/colors.dart';
import '../widgets/row_divider_label.dart';
import '../widgets/section_title.dart';
import '../widgets/will_inkwell.dart';
import 'add_medication_sheet.dart';
import '../widgets/care/hydration_block.dart';
import '../widgets/care/medication_card.dart';

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
    controller = Get.isRegistered<CareController>()
        ? Get.find()
        : Get.put(CareController());
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
          HydrationBlock(controller: controller),
          const SizedBox(height: 28),
          RowDividerLabel(
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
            ...meds.map(
              (m) => MedicationCard(med: m, controller: controller),
            ),
        ],
      );
    });
  }
}
