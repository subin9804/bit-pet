// ============================================================
// Routine domain models (v3.1 redesign — user-owned routines)
// ============================================================

enum RoutineType { FEEDING, CLEANING, WEIGHT, CUSTOM }

enum RoutineLogStatus { COMPLETED, REFUSED }

// -----------------------------------------------------------------------
// Today's routine status (per-pet completion for today)
// -----------------------------------------------------------------------
class TodayRoutine {
  final int id;
  final String title;
  final RoutineType routineType;
  final String? alarmTime;
  final bool isAlarmEnabled;
  final int totalPetCount;
  final int completedPetCount;
  final List<TodayPetStatus> petStatuses;

  const TodayRoutine({
    required this.id,
    required this.title,
    required this.routineType,
    this.alarmTime,
    required this.isAlarmEnabled,
    required this.totalPetCount,
    required this.completedPetCount,
    required this.petStatuses,
  });

  bool get isAllCompleted =>
      totalPetCount > 0 && completedPetCount >= totalPetCount;

  factory TodayRoutine.fromJson(Map<String, dynamic> json) => TodayRoutine(
        id: json['id'] as int,
        title: json['title'] as String,
        routineType: RoutineType.values.firstWhere(
          (e) => e.name == json['routineType'],
          orElse: () => RoutineType.CUSTOM,
        ),
        alarmTime: json['alarmTime'] as String?,
        isAlarmEnabled: json['alarmEnabled'] as bool? ?? false,
        totalPetCount: json['totalPetCount'] as int? ?? 0,
        completedPetCount: json['completedPetCount'] as int? ?? 0,
        petStatuses: (json['petStatuses'] as List<dynamic>? ?? [])
            .map((e) => TodayPetStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  TodayRoutine copyWithPetStatus(int petId, bool isCompleted) {
    final updated = petStatuses.map((s) {
      if (s.petId != petId) return s;
      return TodayPetStatus(
        petId: s.petId,
        petName: s.petName,
        speciesName: s.speciesName,
        colorCode: s.colorCode,
        imageUrl: s.imageUrl,
        isCompleted: isCompleted,
        logId: s.logId,
      );
    }).toList();
    final newCompleted = updated.where((s) => s.isCompleted).length;
    return TodayRoutine(
      id: id,
      title: title,
      routineType: routineType,
      alarmTime: alarmTime,
      isAlarmEnabled: isAlarmEnabled,
      totalPetCount: totalPetCount,
      completedPetCount: newCompleted,
      petStatuses: updated,
    );
  }
}

class TodayPetStatus {
  final int petId;
  final String petName;
  final String speciesName;
  final String? colorCode;
  final String? imageUrl;
  final bool isCompleted;
  final int? logId;

  const TodayPetStatus({
    required this.petId,
    required this.petName,
    required this.speciesName,
    this.colorCode,
    this.imageUrl,
    required this.isCompleted,
    this.logId,
  });

  factory TodayPetStatus.fromJson(Map<String, dynamic> json) => TodayPetStatus(
        petId: json['petId'] as int,
        petName: json['petName'] as String,
        speciesName: json['speciesName'] as String? ?? '',
        colorCode: json['colorCode'] as String?,
        imageUrl: json['imageUrl'] as String?,
        isCompleted: json['completed'] as bool? ?? false,
        logId: json['logId'] as int?,
      );
}

// -----------------------------------------------------------------------
// Routine (user-owned, may be linked to multiple pets)
// -----------------------------------------------------------------------
class Routine {
  final int id;
  final int userId;
  final RoutineType routineType;
  final String title;
  final int cycleDays;
  final String? alarmTime; // "HH:mm"
  final bool isAlarmEnabled;
  final DateTime? lastExecutedAt;
  final DateTime? nextDueAt;
  final bool isActive;
  final String? memo;
  final List<int> petIds;
  final int petCount;

  const Routine({
    required this.id,
    required this.userId,
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.alarmTime,
    required this.isAlarmEnabled,
    this.lastExecutedAt,
    this.nextDueAt,
    required this.isActive,
    this.memo,
    required this.petIds,
    required this.petCount,
  });

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as int,
        userId: json['userId'] as int,
        routineType: RoutineType.values.firstWhere(
          (e) => e.name == json['routineType'],
          orElse: () => RoutineType.CUSTOM,
        ),
        title: json['title'] as String,
        cycleDays: json['cycleDays'] as int,
        alarmTime: json['alarmTime'] as String?,
        isAlarmEnabled: json['alarmEnabled'] as bool? ?? false,
        lastExecutedAt: json['lastExecutedAt'] != null
            ? DateTime.tryParse(json['lastExecutedAt'] as String)
            : null,
        nextDueAt: json['nextDueAt'] != null
            ? DateTime.tryParse(json['nextDueAt'] as String)
            : null,
        isActive: json['active'] as bool? ?? true,
        memo: json['memo'] as String?,
        petIds: (json['petIds'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        petCount: json['petCount'] as int? ?? 0,
      );

  int? get dDayFromNow {
    if (nextDueAt == null) return null;
    return nextDueAt!.difference(DateTime.now()).inDays;
  }
}

// -----------------------------------------------------------------------
// Routine with subscription status (for pet detail tab)
// -----------------------------------------------------------------------
class RoutineWithSubscription {
  final Routine routine;
  final bool subscribed;

  const RoutineWithSubscription({required this.routine, required this.subscribed});

  factory RoutineWithSubscription.fromJson(Map<String, dynamic> json) =>
      RoutineWithSubscription(
        routine: Routine.fromJson(json['routine'] as Map<String, dynamic>),
        subscribed: json['subscribed'] as bool,
      );
}

// -----------------------------------------------------------------------
// RoutineLog (routine_log_dtl)
// -----------------------------------------------------------------------
class RoutineLog {
  final int id;
  final int routineId;
  final int petId;
  final RoutineLogStatus status;
  final DateTime executedAt;
  final Map<String, dynamic>? extraData;
  final String? memo;
  final DateTime createdAt;

  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.petId,
    required this.status,
    required this.executedAt,
    this.extraData,
    this.memo,
    required this.createdAt,
  });

  factory RoutineLog.fromJson(Map<String, dynamic> json) => RoutineLog(
        id: json['id'] as int,
        routineId: json['routineId'] as int,
        petId: json['petId'] as int,
        status: RoutineLogStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => RoutineLogStatus.COMPLETED,
        ),
        executedAt: DateTime.parse(json['executedAt'] as String),
        extraData: json['extraData'] as Map<String, dynamic>?,
        memo: json['memo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// -----------------------------------------------------------------------
// Request DTOs
// -----------------------------------------------------------------------
class CreateRoutineRequest {
  final RoutineType routineType;
  final String title;
  final int cycleDays;
  final String? alarmTime;
  final bool alarmEnabled;
  final List<int> petIds;
  final String? memo;

  const CreateRoutineRequest({
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.alarmTime,
    this.alarmEnabled = false,
    this.petIds = const [],
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'routineType': routineType.name,
        'title': title,
        'cycleDays': cycleDays,
        if (alarmTime != null) 'alarmTime': alarmTime,
        'alarmEnabled': alarmEnabled,
        'petIds': petIds,
        if (memo != null) 'memo': memo,
      };
}

class RoutineCompleteBatchRequest {
  final DateTime? executedAt;
  final String? foodType;
  final double? amount;
  final String? unit;
  final String? feedResponse; // COMPLETE / PARTIAL / REFUSED
  final String? cleaningType; // FULL / PARTIAL / WATER_CHANGE
  final double? weightG;
  final String? memo;

  const RoutineCompleteBatchRequest({
    this.executedAt,
    this.foodType,
    this.amount,
    this.unit,
    this.feedResponse,
    this.cleaningType,
    this.weightG,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        if (executedAt != null) 'executedAt': executedAt!.toIso8601String(),
        if (foodType != null) 'foodType': foodType,
        if (amount != null) 'amount': amount,
        if (unit != null) 'unit': unit,
        if (feedResponse != null) 'feedResponse': feedResponse,
        if (cleaningType != null) 'cleaningType': cleaningType,
        if (weightG != null) 'weightG': weightG,
        if (memo != null) 'memo': memo,
      };
}

class RoutineCompleteIndividualRequest {
  final int petId;
  final RoutineLogStatus status;
  final DateTime? executedAt;
  final String? foodType;
  final double? amount;
  final String? unit;
  final String? feedResponse;
  final String? cleaningType;
  final double? weightG;
  final String? memo;

  const RoutineCompleteIndividualRequest({
    required this.petId,
    required this.status,
    this.executedAt,
    this.foodType,
    this.amount,
    this.unit,
    this.feedResponse,
    this.cleaningType,
    this.weightG,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'petId': petId,
        'status': status.name,
        if (executedAt != null) 'executedAt': executedAt!.toIso8601String(),
        if (foodType != null) 'foodType': foodType,
        if (amount != null) 'amount': amount,
        if (unit != null) 'unit': unit,
        if (feedResponse != null) 'feedResponse': feedResponse,
        if (cleaningType != null) 'cleaningType': cleaningType,
        if (weightG != null) 'weightG': weightG,
        if (memo != null) 'memo': memo,
      };
}
