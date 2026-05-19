class Routine {
  final int id;
  final int petId;
  final String routineType; // FEEDING / CLEANING / WEIGHT / CUSTOM
  final String title;
  final int cycleDays;
  final String? alarmTime;
  final bool isAlarmEnabled;
  final DateTime? lastExecutedAt;
  final DateTime? nextDueAt;
  final bool isActive;
  final String? memo;

  const Routine({
    required this.id,
    required this.petId,
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.alarmTime,
    required this.isAlarmEnabled,
    this.lastExecutedAt,
    this.nextDueAt,
    required this.isActive,
    this.memo,
  });

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as int,
        petId: json['petId'] as int,
        routineType: json['routineType'] as String,
        title: json['title'] as String,
        cycleDays: json['cycleDays'] as int,
        alarmTime: json['alarmTime'] as String?,
        isAlarmEnabled: json['isAlarmEnabled'] as bool? ?? false,
        lastExecutedAt: json['lastExecutedAt'] != null
            ? DateTime.tryParse(json['lastExecutedAt'] as String)
            : null,
        nextDueAt: json['nextDueAt'] != null
            ? DateTime.tryParse(json['nextDueAt'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
        memo: json['memo'] as String?,
      );

  int? get dDayFromNow {
    if (nextDueAt == null) return null;
    return nextDueAt!.difference(DateTime.now()).inDays;
  }
}

class CreateRoutineRequest {
  final int petId;
  final String routineType;
  final String title;
  final int cycleDays;
  final String? alarmTime;
  final bool isAlarmEnabled;
  final String? memo;

  const CreateRoutineRequest({
    required this.petId,
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.alarmTime,
    this.isAlarmEnabled = false,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'petId': petId,
        'routineType': routineType,
        'title': title,
        'cycleDays': cycleDays,
        if (alarmTime != null) 'alarmTime': alarmTime,
        'isAlarmEnabled': isAlarmEnabled,
        if (memo != null) 'memo': memo,
      };
}
