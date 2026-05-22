import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../models/medication.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';
import '../widgets/will_text_field.dart';
import 'care_controller.dart';

class AddMedicationSheet extends StatefulWidget {
  const AddMedicationSheet({super.key});

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _dose.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final med = Medication(
      id: 'med_${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      dose: _dose.text.trim(),
      times: List.of(_times),
    );
    await Get.find<CareController>().saveMedication(med);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
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
                'Add medication',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              WillTextField(
                controller: _name,
                label: 'Name',
                hint: 'Hydroxyurea',
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              WillTextField(
                controller: _dose,
                label: 'Dose',
                hint: '500 mg',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 18),
              const Text(
                'TIMES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WillColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _times.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: WillInkwell(
                          onTap: () => _pickTime(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: WillColors.surface,
                              border: Border.all(
                                color:
                                    WillColors.border.withValues(alpha: 0.6),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.clock,
                                  size: 18,
                                  color: WillColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _times[i].format(context),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: WillColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_times.length > 1)
                        IconButton(
                          onPressed: () => setState(() => _times.removeAt(i)),
                          icon: const Icon(
                            CupertinoIcons.minus_circle,
                            color: WillColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              WillInkwell(
                onTap: () => setState(() => _times
                    .add(const TimeOfDay(hour: 20, minute: 0))),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.add_circled,
                        size: 18,
                        color: WillColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add another time',
                        style: TextStyle(
                          color: WillColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              WillPrimaryButton(
                label: 'Save medication',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
