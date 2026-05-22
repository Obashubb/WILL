import 'package:flutter/material.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.times,
    this.active = true,
    this.notes,
  });

  final String id;
  final String name;
  final String dose;
  final List<TimeOfDay> times;
  final bool active;
  final String? notes;

  Medication copyWith({
    String? name,
    String? dose,
    List<TimeOfDay>? times,
    bool? active,
    String? notes,
  }) =>
      Medication(
        id: id,
        name: name ?? this.name,
        dose: dose ?? this.dose,
        times: times ?? this.times,
        active: active ?? this.active,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
        'active': active,
        if (notes != null) 'notes': notes,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        name: json['name'] as String,
        dose: json['dose'] as String,
        times: (json['times'] as List)
            .map((s) => _parseTime(s as String))
            .toList(),
        active: json['active'] as bool? ?? true,
        notes: json['notes'] as String?,
      );

  static TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

enum MedicationLogStatus { taken, skipped }

class MedicationLog {
  const MedicationLog({
    required this.medicationId,
    required this.scheduledFor,
    required this.actedAt,
    required this.status,
  });

  final String medicationId;
  final DateTime scheduledFor;
  final DateTime actedAt;
  final MedicationLogStatus status;

  Map<String, dynamic> toJson() => {
        'medId': medicationId,
        'scheduledFor': scheduledFor.millisecondsSinceEpoch,
        'actedAt': actedAt.millisecondsSinceEpoch,
        'status': status.name,
      };

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
        medicationId: json['medId'] as String,
        scheduledFor:
            DateTime.fromMillisecondsSinceEpoch(json['scheduledFor'] as int),
        actedAt: DateTime.fromMillisecondsSinceEpoch(json['actedAt'] as int),
        status: MedicationLogStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MedicationLogStatus.taken,
        ),
      );
}
