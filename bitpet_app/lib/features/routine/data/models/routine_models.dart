// ============================================================
// Routine domain models (v3.1 redesign — user-owned routines)
// ============================================================

import '../../../record/data/food_catalog.dart';

enum RoutineType { FEEDING, CLEANING, WEIGHT, CUSTOM }

/// 서버의 `LocalTime` 을 **항상 `"HH:mm"`** 으로 맞춰 받는다.
///
/// 자릿수가 고정이 아니라서 그냥 `as String?` 로 받으면 안 된다 —
/// Jackson 은 초가 0이면 `"09:00"`, 아니면 `"09:00:30"` 으로 쓰고,
/// `write-dates-as-timestamps` 가 켜지는 순간 `[9, 0]` 배열이 된다.
/// 받는 쪽마다 `split(':')` 자릿수를 세는 코드가 흩어져 있으면,
/// 형태가 하나만 어긋나도 그 화면이 **조용히 기본값으로 떨어진다**
/// (루틴 수정 폼이 09:00 으로 되돌아가 원래 시간을 덮어쓴 적이 있다).
String? normalizeAlarmTime(dynamic raw) {
  int? h, m;
  if (raw is String) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    h = int.tryParse(parts[0]);
    m = int.tryParse(parts[1]);
  } else if (raw is List && raw.length >= 2) {
    h = raw[0] is int ? raw[0] as int : int.tryParse('${raw[0]}');
    m = raw[1] is int ? raw[1] as int : int.tryParse('${raw[1]}');
  } else {
    return null;
  }
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

enum RoutineLogStatus { COMPLETED, REFUSED }

// -----------------------------------------------------------------------
// 반복 규칙 — 서버 V19 (cycle_mode / cycle_days_of_week / cycle_days_of_month)
// -----------------------------------------------------------------------
enum RoutineCycleMode { INTERVAL, WEEKDAY, MONTHDAY }

/// 루틴 반복 규칙. 목록 라벨·캘린더 표시·미루기 계산이 **모두 여기 하나를 본다**.
///
/// 요일은 서버와 같은 **ISO (1=월 … 7=일)** 이다 — Dart `DateTime.weekday` 와도 같다.
/// 폼 화면은 일요일부터 그리느라 0=일~6=토 를 쓰는데, 그 변환은
/// [isoFromAppWeekday]/[appWeekdayFromIso] 두 곳에서만 한다.
///
/// ⚠️ 예전엔 서버에 요일·날짜를 받을 칸이 없어 앱이 `cycleDays` 하나로 뭉갰다
/// (월·수·금 → 1 = '매일', 매월 N일 → 30 = '월 1회').
class RoutineCycle {
  final RoutineCycleMode mode;

  /// INTERVAL 의 간격. 요일·날짜 모드에선 미루기 프리셋의 '한 주기' 길이(7/30)일 뿐이다.
  final int cycleDays;
  final List<int> daysOfWeek;  // ISO 1=월 … 7=일
  final List<int> daysOfMonth; // 1~31, 32=말일

  static const lastDayOfMonth = 32;

  const RoutineCycle({
    this.mode = RoutineCycleMode.INTERVAL,
    this.cycleDays = 1,
    this.daysOfWeek = const [],
    this.daysOfMonth = const [],
  });

  bool get isInterval => mode == RoutineCycleMode.INTERVAL;

  static int isoFromAppWeekday(int d) => d == 0 ? 7 : d;
  static int appWeekdayFromIso(int iso) => iso % 7;

  static RoutineCycleMode parseMode(dynamic raw) =>
      RoutineCycleMode.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => RoutineCycleMode.INTERVAL,
      );

  static List<int> parseInts(dynamic raw) =>
      (raw as List<dynamic>? ?? const [])
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .toList()
        ..sort();

  /// 그 날이 해당일인가 (요일·날짜 모드 전용 — INTERVAL 은 기준일이 있어야 해서 따로 판정한다).
  /// 그 달에 없는 날(2/30 등)은 건너뛴다. 서버 `nextOccurrenceOnOrAfter` 와 같은 규칙.
  bool occursOn(DateTime d) {
    switch (mode) {
      case RoutineCycleMode.INTERVAL:
        return false;
      case RoutineCycleMode.WEEKDAY:
        return daysOfWeek.contains(d.weekday);
      case RoutineCycleMode.MONTHDAY:
        final lastDay = DateTime(d.year, d.month + 1, 0).day;
        return daysOfMonth.contains(d.day) ||
            (d.day == lastDay && daysOfMonth.contains(lastDayOfMonth));
    }
  }

  /// [from] 을 포함한 첫 해당일. INTERVAL 이거나 선택이 비었으면 [from] 그대로.
  DateTime nextOnOrAfter(DateTime from) {
    if (isInterval) return from;
    final start = DateTime(from.year, from.month, from.day);
    final limit = mode == RoutineCycleMode.WEEKDAY ? 7 : 366;
    for (var i = 0; i < limit; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      if (occursOn(d)) return d;
    }
    return start;
  }

  /// 목록·카드에 쓰는 짧은 라벨.
  String get label {
    switch (mode) {
      case RoutineCycleMode.INTERVAL:
        if (cycleDays == 1) return '매일';
        if (cycleDays == 7) return '매주';
        if (cycleDays == 30) return '월 1회';
        return '$cycleDays일마다';
      case RoutineCycleMode.WEEKDAY:
        if (daysOfWeek.length == 7) return '매일';
        if (daysOfWeek.isEmpty) return '요일 미선택';
        const ko = ['', '월', '화', '수', '목', '금', '토', '일'];
        return daysOfWeek.map((d) => ko[d]).join('·');
      case RoutineCycleMode.MONTHDAY:
        if (daysOfMonth.isEmpty) return '날짜 미선택';
        return '매월 ${daysOfMonth.map((d) => d == lastDayOfMonth ? '말일' : '$d일').join('·')}';
    }
  }

  Map<String, dynamic> toJson() => {
        'cycleDays': cycleDays,
        'cycleMode': mode.name,
        'daysOfWeek': mode == RoutineCycleMode.WEEKDAY ? daysOfWeek : const <int>[],
        'daysOfMonth': mode == RoutineCycleMode.MONTHDAY ? daysOfMonth : const <int>[],
      };

  factory RoutineCycle.fromJson(Map<String, dynamic> json) => RoutineCycle(
        mode: parseMode(json['cycleMode']),
        cycleDays: json['cycleDays'] as int? ?? 1,
        daysOfWeek: parseInts(json['daysOfWeek']),
        daysOfMonth: parseInts(json['daysOfMonth']),
      );
}

// -----------------------------------------------------------------------
// Today's routine status (per-pet completion for today)
// -----------------------------------------------------------------------
class TodayRoutine {
  final int id;
  final String title;
  final RoutineType routineType;
  final String? alarmTime;
  final bool isAlarmEnabled;
  final int cycleDays;          // 미루기 날짜 프리셋 계산용
  final RoutineCycle cycle;      // 반복 규칙 (요일·날짜 모드면 미루기 '이번만 건너뛰기' 계산에 쓴다)
  final DateTime? nextDueAt;    // 현재 예정일 (보통 오늘)
  final int totalPetCount;
  final int completedPetCount;
  final List<TodayPetStatus> petStatuses;

  const TodayRoutine({
    required this.id,
    required this.title,
    required this.routineType,
    this.alarmTime,
    required this.isAlarmEnabled,
    this.cycleDays = 1,
    this.cycle = const RoutineCycle(),
    this.nextDueAt,
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
        alarmTime: normalizeAlarmTime(json['alarmTime']),
        isAlarmEnabled: json['alarmEnabled'] as bool? ?? false,
        cycleDays: json['cycleDays'] as int? ?? 1,
        cycle: RoutineCycle.fromJson(json),
        nextDueAt: json['nextDueAt'] != null
            ? DateTime.tryParse(json['nextDueAt'] as String)
            : null,
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
      cycleDays: cycleDays,
      cycle: cycle,
      nextDueAt: nextDueAt,
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
  final RoutineCycle cycle;
  final String? alarmTime; // "HH:mm"
  final bool isAlarmEnabled;
  final DateTime? startDate; // 루틴 시작일 (고정) — 캘린더 표시 하한
  final DateTime? lastExecutedAt;
  final DateTime? nextDueAt;
  final bool isActive;
  final String? memo;
  final DateTime? postponedAt;   // 미룬 적 있으면 그 시각
  final DateTime? postponedFrom; // 미루기 직전 예정일
  final List<int> petIds;
  final int petCount;
  final DateTime? createdAt;

  bool get isPostponed => postponedAt != null;

  const Routine({
    required this.id,
    required this.userId,
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.cycle = const RoutineCycle(),
    this.alarmTime,
    required this.isAlarmEnabled,
    this.startDate,
    this.lastExecutedAt,
    this.nextDueAt,
    required this.isActive,
    this.memo,
    this.postponedAt,
    this.postponedFrom,
    required this.petIds,
    required this.petCount,
    this.createdAt,
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
        cycle: RoutineCycle.fromJson(json),
        alarmTime: normalizeAlarmTime(json['alarmTime']),
        isAlarmEnabled: json['alarmEnabled'] as bool? ?? false,
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'] as String)
            : null,
        lastExecutedAt: json['lastExecutedAt'] != null
            ? DateTime.tryParse(json['lastExecutedAt'] as String)
            : null,
        nextDueAt: json['nextDueAt'] != null
            ? DateTime.tryParse(json['nextDueAt'] as String)
            : null,
        isActive: json['active'] as bool? ?? true,
        memo: json['memo'] as String?,
        postponedAt: json['postponedAt'] != null
            ? DateTime.tryParse(json['postponedAt'] as String)
            : null,
        postponedFrom: json['postponedFrom'] != null
            ? DateTime.tryParse(json['postponedFrom'] as String)
            : null,
        petIds: (json['petIds'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        petCount: json['petCount'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  int? get dDayFromNow {
    if (nextDueAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due   = DateTime(nextDueAt!.year, nextDueAt!.month, nextDueAt!.day);
    return due.difference(today).inDays;
  }
}

// -----------------------------------------------------------------------
// Routine with subscription status (for pet detail tab)
// -----------------------------------------------------------------------
class RoutineWithSubscription {
  final Routine routine;
  final bool subscribed;
  final bool todayCompleted;
  final int? todayLogId;

  const RoutineWithSubscription({
    required this.routine,
    required this.subscribed,
    this.todayCompleted = false,
    this.todayLogId,
  });

  factory RoutineWithSubscription.fromJson(Map<String, dynamic> json) =>
      RoutineWithSubscription(
        routine: Routine.fromJson(json['routine'] as Map<String, dynamic>),
        subscribed: json['subscribed'] as bool? ?? false,
        todayCompleted: json['todayCompleted'] as bool? ?? false,
        todayLogId: json['todayLogId'] as int?,
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
  final String? memo;
  final double? weightG;               // 연결된 weight_dtl 에서 파생
  final List<FeedFormData> feedItems;  // 연결된 feeding_dtl 에서 파생
  final DateTime createdAt;

  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.petId,
    required this.status,
    required this.executedAt,
    this.memo,
    this.weightG,
    this.feedItems = const [],
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
        memo: json['memo'] as String?,
        weightG: (json['weightG'] as num?)?.toDouble(),
        feedItems: (json['feedItems'] as List?)
                ?.map((e) => FeedFormData.fromApiMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
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
  final DateTime? startAt;
  final RoutineCycle? cycle;

  const CreateRoutineRequest({
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.cycle,
    this.alarmTime,
    this.alarmEnabled = false,
    this.petIds = const [],
    this.memo,
    this.startAt,
  });

  Map<String, dynamic> toJson() => {
        'routineType': routineType.name,
        'title': title,
        'cycleDays': cycleDays,
        if (alarmTime != null) 'alarmTime': alarmTime,
        'alarmEnabled': alarmEnabled,
        'petIds': petIds,
        if (memo != null) 'memo': memo,
        if (startAt != null) 'startAt': startAt!.toUtc().toIso8601String(),
        if (cycle != null) ...cycle!.toJson(),
      };
}

class RoutineCompleteBatchRequest {
  final DateTime? executedAt;
  final List<FeedFormData> feedItems;
  final String? cleaningType;
  final double? weightG;
  final String? memo;

  const RoutineCompleteBatchRequest({
    this.executedAt,
    this.feedItems = const [],
    this.cleaningType,
    this.weightG,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
    if (executedAt != null) 'executedAt': executedAt!.toUtc().toIso8601String(),
    if (feedItems.isNotEmpty)
      'feedItems': feedItems
          .map((f) => f.toApiMap())
          .where((m) => m.isNotEmpty)
          .toList(),
    if (cleaningType != null) 'cleaningType': cleaningType,
    if (weightG != null) 'weightG': weightG,
    if (memo != null) 'memo': memo,
  };
}

class RoutineCompleteIndividualRequest {
  final int petId;
  final RoutineLogStatus status;
  final DateTime? executedAt;
  final List<FeedFormData> feedItems;
  final String? cleaningType;
  final double? weightG;
  final String? memo;

  const RoutineCompleteIndividualRequest({
    required this.petId,
    required this.status,
    this.executedAt,
    this.feedItems = const [],
    this.cleaningType,
    this.weightG,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
    'petId':  petId,
    'status': status.name,
    if (executedAt != null) 'executedAt': executedAt!.toUtc().toIso8601String(),
    if (feedItems.isNotEmpty)
      'feedItems': feedItems
          .map((f) => f.toApiMap())
          .where((m) => m.isNotEmpty)
          .toList(),
    if (cleaningType != null) 'cleaningType': cleaningType,
    if (weightG != null) 'weightG': weightG,
    if (memo != null) 'memo': memo,
  };
}
