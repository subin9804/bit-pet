class WeightRecord {
  final int id;
  final int petId;
  final double weightG;
  final DateTime measuredAt;
  final String source;
  final String? memo;

  const WeightRecord({
    required this.id,
    required this.petId,
    required this.weightG,
    required this.measuredAt,
    required this.source,
    this.memo,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        id: json['id'] as int,
        petId: json['petId'] as int,
        weightG: (json['weightG'] as num).toDouble(),
        measuredAt: DateTime.parse(json['measuredAt'] as String),
        source: json['source'] as String? ?? 'MANUAL',
        memo: json['memo'] as String?,
      );
}

enum FeedResponse { COMPLETE, PARTIAL, REFUSED }

class FeedingRecord {
  final int id;
  final int petId;
  final int? routineId;
  final String foodType;
  final double? amount;
  final String? unit;
  final FeedResponse? feedResponse;
  final DateTime fedAt;
  final String? memo;

  const FeedingRecord({
    required this.id,
    required this.petId,
    this.routineId,
    required this.foodType,
    this.amount,
    this.unit,
    this.feedResponse,
    required this.fedAt,
    this.memo,
  });

  factory FeedingRecord.fromJson(Map<String, dynamic> json) => FeedingRecord(
        id: json['id'] as int,
        petId: json['petId'] as int,
        routineId: json['routineId'] as int?,
        foodType: json['foodType'] as String,
        amount: (json['amount'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        feedResponse: json['feedResponse'] != null
            ? FeedResponse.values.firstWhere(
                (e) => e.name == json['feedResponse'],
                orElse: () => FeedResponse.COMPLETE,
              )
            : null,
        fedAt: DateTime.parse(json['fedAt'] as String),
        memo: json['memo'] as String?,
      );
}

enum CleaningType { FULL, PARTIAL, WATER_CHANGE }

class CleaningRecord {
  final int id;
  final int petId;
  final CleaningType cleaningType;
  final DateTime cleanedAt;
  final String? memo;
  final DateTime createdAt;

  const CleaningRecord({
    required this.id,
    required this.petId,
    required this.cleaningType,
    required this.cleanedAt,
    this.memo,
    required this.createdAt,
  });

  factory CleaningRecord.fromJson(Map<String, dynamic> json) => CleaningRecord(
        id: json['id'] as int,
        petId: json['petId'] as int,
        cleaningType: CleaningType.values.firstWhere(
          (e) => e.name == json['cleaningType'],
          orElse: () => CleaningType.FULL,
        ),
        cleanedAt: DateTime.parse(json['cleanedAt'] as String),
        memo: json['memo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ── Memo (v5) ──────────────────────────────────────────────

class MemoTag {
  final String code;
  final String labelKo;
  final int displayOrder;

  const MemoTag({
    required this.code,
    required this.labelKo,
    required this.displayOrder,
  });

  factory MemoTag.fromJson(Map<String, dynamic> json) => MemoTag(
        code: json['code'] as String,
        labelKo: json['labelKo'] as String,
        displayOrder: json['displayOrder'] as int,
      );
}

class MemoVetExt {
  final String? clinicName;
  final int? cost;
  final DateTime? nextVisitAt;

  const MemoVetExt({this.clinicName, this.cost, this.nextVisitAt});

  factory MemoVetExt.fromJson(Map<String, dynamic> json) => MemoVetExt(
        clinicName: json['clinicName'] as String?,
        cost: json['cost'] as int?,
        nextVisitAt: json['nextVisitAt'] != null
            ? DateTime.parse(json['nextVisitAt'] as String)
            : null,
      );
}

class Memo {
  final int id;
  final int petId;
  final String content;
  final DateTime loggedAt;
  final List<String> tags;
  final MemoVetExt? vetExt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memo({
    required this.id,
    required this.petId,
    required this.content,
    required this.loggedAt,
    required this.tags,
    this.vetExt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) => Memo(
        id: json['memoId'] as int,
        petId: json['petId'] as int,
        content: json['content'] as String,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        vetExt: json['vetExt'] != null
            ? MemoVetExt.fromJson(json['vetExt'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// ── Mating (v5) ────────────────────────────────────────────

class MatingRecord {
  final int id;
  final int? malePetId;
  final int? femalePetId;
  final DateTime triedAt;
  final String? seasonLabel;
  final bool? isSuccessful;
  final String? memo;
  final DateTime createdAt;

  const MatingRecord({
    required this.id,
    this.malePetId,
    this.femalePetId,
    required this.triedAt,
    this.seasonLabel,
    this.isSuccessful,
    this.memo,
    required this.createdAt,
  });

  factory MatingRecord.fromJson(Map<String, dynamic> json) => MatingRecord(
        id: json['id'] as int,
        malePetId: json['malePetId'] as int?,
        femalePetId: json['femalePetId'] as int?,
        triedAt: DateTime.parse(json['triedAt'] as String),
        seasonLabel: json['seasonLabel'] as String?,
        isSuccessful: json['isSuccessful'] as bool?,
        memo: json['memo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ── Laying (v5) ────────────────────────────────────────────

enum HatchStatus { PENDING, HATCHED, FAILED, SLUG }

class HatchRecord {
  final int id;
  final int layingId;
  final int eggIndex;
  final HatchStatus status;
  final DateTime? hatchedAt;
  final String? memo;

  const HatchRecord({
    required this.id,
    required this.layingId,
    required this.eggIndex,
    required this.status,
    this.hatchedAt,
    this.memo,
  });

  factory HatchRecord.fromJson(Map<String, dynamic> json) => HatchRecord(
        id: json['id'] as int,
        layingId: json['layingId'] as int,
        eggIndex: json['eggIndex'] as int,
        status: HatchStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => HatchStatus.PENDING,
        ),
        hatchedAt: json['hatchedAt'] != null
            ? DateTime.parse(json['hatchedAt'] as String)
            : null,
        memo: json['memo'] as String?,
      );
}

class LayingRecord {
  final int id;
  final int petId;
  final DateTime laidAt;
  final int totalCount;
  final String? memo;
  final List<HatchRecord> hatches;
  final DateTime createdAt;

  const LayingRecord({
    required this.id,
    required this.petId,
    required this.laidAt,
    required this.totalCount,
    this.memo,
    required this.hatches,
    required this.createdAt,
  });

  factory LayingRecord.fromJson(Map<String, dynamic> json) => LayingRecord(
        id: json['id'] as int,
        petId: json['petId'] as int,
        laidAt: DateTime.parse(json['laidAt'] as String),
        totalCount: json['totalCount'] as int,
        memo: json['memo'] as String?,
        hatches: (json['hatches'] as List?)
                ?.map((e) => HatchRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ── Calendar (v5) ──────────────────────────────────────────

class CalendarDay {
  final String date; // YYYY-MM-DD
  final List<String> categories; // WEIGHT, FEEDING, CLEANING, MEMO, MATING, LAYING

  const CalendarDay({required this.date, required this.categories});

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: json['date'] as String,
        categories: (json['categories'] as List).cast<String>(),
      );
}

// ── Timeline (v5) ──────────────────────────────────────────

class TimelineItem {
  final int id;
  final String category; // WEIGHT, FEEDING, CLEANING, MEMO, MATING, LAYING
  final String summary;
  final DateTime recordedAt;

  const TimelineItem({
    required this.id,
    required this.category,
    required this.summary,
    required this.recordedAt,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) => TimelineItem(
        id: json['id'] as int,
        category: json['category'] as String,
        summary: json['summary'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}

// ── 홈 화면 최근 기록 통합 피드 ──────────────────────────────

class RecentRecord {
  final int id;
  final String petName;
  final String? colorCode;
  final String recordType; // FEEDING, WEIGHT, CLEANING, MEMO
  final String summary;
  final DateTime createdAt;

  const RecentRecord({
    required this.id,
    required this.petName,
    this.colorCode,
    required this.recordType,
    required this.summary,
    required this.createdAt,
  });

  factory RecentRecord.fromJson(Map<String, dynamic> json) => RecentRecord(
        id: json['id'] as int,
        petName: json['petName'] as String,
        colorCode: json['colorCode'] as String?,
        recordType: json['recordType'] as String,
        summary: json['summary'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
