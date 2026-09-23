import '../food_catalog.dart';

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

class FeedingRecord {
  final int id;
  final int petId;
  final int? routineId;
  /// 거식(refused=true)이면 서버가 먹이 종류를 주지 않는다 → null
  final String? foodType;
  final double? amount;
  final String? unit;
  final String? sizeLabel;
  final FeedingSupplement? supplement;
  final DateTime fedAt;
  final String? memo;
  /// 먹이를 거부한 기록
  final bool refused;

  const FeedingRecord({
    required this.id,
    required this.petId,
    this.routineId,
    this.foodType,
    this.amount,
    this.unit,
    this.sizeLabel,
    this.supplement,
    required this.fedAt,
    this.memo,
    this.refused = false,
  });

  factory FeedingRecord.fromJson(Map<String, dynamic> json) => FeedingRecord(
        id: json['id'] as int,
        petId: json['petId'] as int,
        routineId: json['routineId'] as int?,
        foodType: json['foodType'] as String?,
        refused: json['refused'] as bool? ?? false,
        amount: (json['amount'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        sizeLabel: json['sizeLabel'] as String?,
        supplement: json['supplement'] != null
            ? FeedingSupplement.values.firstWhere(
                (e) => e.name == json['supplement'],
                orElse: () => FeedingSupplement.OTHER)
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
        // 서버 응답 키는 label/order (labelKo/displayOrder 아님) — 하위호환 위해 둘 다 허용
        labelKo: (json['label'] ?? json['labelKo']) as String,
        displayOrder: (json['order'] ?? json['displayOrder']) as int,
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
  final String? routineTitle; // 루틴 완료로 생성된 메모면 해당 루틴 제목
  // false면 루틴 완료 합성 항목 → 실제 memo가 아니라 수정/삭제 불가
  final bool editable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memo({
    required this.id,
    required this.petId,
    required this.content,
    required this.loggedAt,
    required this.tags,
    this.vetExt,
    this.routineTitle,
    this.editable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) => Memo(
        id: json['memoId'] as int,
        petId: json['petId'] as int,
        content: json['content'] as String,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        tags: (json['tags'] as List?)?.whereType<String>().toList() ?? [],
        vetExt: json['vetExt'] != null
            ? MemoVetExt.fromJson(json['vetExt'] as Map<String, dynamic>)
            : null,
        routineTitle: json['routineTitle'] as String?,
        editable: json['editable'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// 목록 표시용 — 루틴發 메모는 "[루틴제목] 내용" (편집 시에는 content만 사용)
  String get displayContent =>
      routineTitle != null ? '[$routineTitle] $content' : content;
}

// ── Mating (v5) ────────────────────────────────────────────

class MatingRecord {
  final int id;
  final int? malePetId;
  final int? femalePetId;
  /// 상대 개체 이름 — 서버가 `petMaleSummary`/`petFemaleSummary` 로 같이 내려준다.
  /// 이름을 들고 있지 않으면 수정 폼에서 파트너를 'id #12' 로밖에 못 보여준다.
  final String? malePetName;
  final String? femalePetName;
  final String? externalPartnerText;
  final DateTime triedAt;
  final String? seasonLabel;
  final bool? isSuccessful;
  final String? memo;
  final DateTime createdAt;

  const MatingRecord({
    required this.id,
    this.malePetId,
    this.femalePetId,
    this.malePetName,
    this.femalePetName,
    this.externalPartnerText,
    required this.triedAt,
    this.seasonLabel,
    this.isSuccessful,
    this.memo,
    required this.createdAt,
  });

  factory MatingRecord.fromJson(Map<String, dynamic> json) => MatingRecord(
        // 서버 키는 `matingId`(`MatingResponse`). `id` 는 폴백일 뿐이다 —
        // 예전엔 `id` 만 읽어서 교배 기록이 한 건이라도 있으면 목록이 통째로 터졌다.
        id: (json['matingId'] ?? json['id']) as int,
        malePetId: (json['petIdMale'] ?? json['malePetId']) as int?,
        femalePetId: (json['petIdFemale'] ?? json['femalePetId']) as int?,
        malePetName:
            (json['petMaleSummary'] as Map<String, dynamic>?)?['name'] as String?,
        femalePetName:
            (json['petFemaleSummary'] as Map<String, dynamic>?)?['name'] as String?,
        externalPartnerText: json['externalPartnerText'] as String?,
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
        // 서버 키는 `hatchId`(`HatchResponse`). 그 응답엔 layingId·eggIndex 가
        // 아예 없어서(부모 산란 기록 안에 배열로 들어온다) 기본값으로 받는다.
        id: (json['hatchId'] ?? json['id']) as int,
        layingId: (json['layingId'] as int?) ?? 0,
        eggIndex: (json['eggIndex'] as int?) ?? 0,
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
        // 서버 키는 `layingId` / `eggCountTotal`(`LayingResponse`).
        id: (json['layingId'] ?? json['id']) as int,
        petId: (json['petId'] as int?) ?? 0,
        laidAt: DateTime.parse(json['laidAt'] as String),
        totalCount: ((json['eggCountTotal'] ?? json['totalCount']) as num).toInt(),
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
        categories: (json['categories'] as List?)?.whereType<String>().toList() ?? [],
      );
}

// ── Timeline (v5) ──────────────────────────────────────────

class TimelineItem {
  final int id;
  final String category; // WEIGHT, FEEDING, CLEANING, MEMO, MATING, LAYING
  final String summary;
  final String? routineTitle; // 루틴 완료로 생성된 기록이면 해당 루틴 제목
  final DateTime recordedAt;

  const TimelineItem({
    required this.id,
    required this.category,
    required this.summary,
    this.routineTitle,
    required this.recordedAt,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) => TimelineItem(
        id: ((json['recordId'] ?? json['id']) as num? ?? 0).toInt(),
        category: json['category'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        routineTitle: json['routineTitle'] as String?,
        recordedAt: DateTime.parse(
            (json['loggedAt'] ?? json['recordedAt']) as String),
      );

  /// 기록 표시 텍스트 — 루틴發 기록은 앞에 [루틴제목]을 붙인다.
  /// 부가정보 없는 완료(summary == 루틴제목)는 "[제목] 완료"로 표시.
  String get displayText {
    if (routineTitle == null) return summary;
    if (routineTitle == summary) return '[$routineTitle] 완료';
    return '[$routineTitle] $summary';
  }
}

// ── 홈 화면 최근 기록 통합 피드 ──────────────────────────────

class RecentRecord {
  final int id;
  final int? petId;
  final String petName;
  final String? colorCode;
  final String recordType;
  final String summary;
  final String? memo;
  final DateTime createdAt;

  const RecentRecord({
    required this.id,
    this.petId,
    required this.petName,
    this.colorCode,
    required this.recordType,
    required this.summary,
    this.memo,
    required this.createdAt,
  });

  factory RecentRecord.fromJson(Map<String, dynamic> json) => RecentRecord(
        id: (json['id'] as num).toInt(),
        petId: (json['petId'] as num?)?.toInt(),
        petName: json['petName'] as String? ?? '',
        colorCode: json['colorCode'] as String?,
        recordType: json['recordType'] as String,
        summary: json['summary'] as String? ?? '',
        memo: json['memo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
