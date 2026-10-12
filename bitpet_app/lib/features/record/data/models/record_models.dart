import '../food_catalog.dart';

/// 이 개체에게 산란 기록이 성립하는가.
///
/// 서버도 산란은 FEMALE 만 받는다(`LayingService`) — 수컷 개체 상세에 산란 줄을
/// 띄워두면 눌러도 빈 목록이거나 저장에서 튕긴다.
///
/// **성별 미상(UNKNOWN)은 보여준다.** 어린 개체는 성별이 나중에 갈리는데
/// 여기서 같이 감추면 정작 알을 낳았을 때 기록할 자리가 없다.
/// 감추는 건 "아닌 게 확실한" 수컷뿐이다.
bool canLayEggs(String gender) => gender != 'MALE';

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
  /// 루틴 완료로 생긴 기록이면 그 루틴 제목 (직접 적은 기록은 null)
  final String? routineTitle;

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
    this.routineTitle,
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
        routineTitle: json['routineTitle'] as String?,
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
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// 목록 표시용. ⛔ 루틴 제목을 붙이지 않는다 — 이건 루틴이 아니라 **메모 기록**이다.
  /// 내용이 비어 있으면 메모 없이 완료한 루틴 기록이다 ('완료' 자체가 기록).
  String get displayContent => content.isEmpty ? '메모 미입력' : content;
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

  /// 이 알이 개체로 등록됐으면 그 개체 id. 등록된 알은 상태 순환에서 빠진다
  /// (서버도 `HATCH_ALREADY_REGISTERED` 로 막는다).
  final int? hatchedPetId;
  final String? hatchedPetName;

  const HatchRecord({
    required this.id,
    required this.layingId,
    required this.eggIndex,
    required this.status,
    this.hatchedAt,
    this.memo,
    this.hatchedPetId,
    this.hatchedPetName,
  });

  bool get isRegistered => hatchedPetId != null;

  factory HatchRecord.fromJson(Map<String, dynamic> json) {
    final summary = json['hatchedPetSummary'] as Map<String, dynamic>?;
    return HatchRecord(
      // 서버 키는 `hatchId`(`HatchResponse`). 그 응답엔 layingId 가 없어서
      // (부모 산란 기록 안에 배열로 들어온다) 기본값으로 받는다.
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
      hatchedPetId: json['hatchedPetId'] as int?,
      hatchedPetName: summary?['name'] as String?,
    );
  }
}

/// 클러치의 날짜별 관찰 메모 (`laying_note_dtl`).
///
/// 산란 기록 자체의 `memo` 와 다른 것이다 — 저쪽은 클러치당 한 칸이라
/// "며칠에 무엇을 봤다"를 쌓을 수 없다.
class LayingNote {
  final int id;
  final int layingId;
  final DateTime notedAt;
  final String content;

  const LayingNote({
    required this.id,
    required this.layingId,
    required this.notedAt,
    required this.content,
  });

  factory LayingNote.fromJson(Map<String, dynamic> json) => LayingNote(
        id: (json['noteId'] ?? json['id']) as int,
        layingId: (json['layingId'] as int?) ?? 0,
        notedAt: DateTime.parse(json['notedAt'] as String),
        content: json['content'] as String? ?? '',
      );
}

class LayingRecord {
  final int id;
  final int petId;

  /// 어미 이름·종 — '알' 탭 카드가 개체를 따로 조회하지 않도록 서버가 같이 내린다.
  /// 개체 상세의 산란 목록(`/pets/:id/layings`)에서는 비어 있다.
  final String? petName;
  final String? speciesName;

  final DateTime laidAt;
  final int totalCount;
  final String? memo;

  /// 인큐베이터 설정값 — 클러치 상세 요약 캡션에만 쓴다.
  final double? incubationTemp;
  final double? incubationHumidity;
  final List<HatchRecord> hatches;
  final List<LayingNote> notes;
  final DateTime createdAt;

  const LayingRecord({
    required this.id,
    required this.petId,
    this.petName,
    this.speciesName,
    required this.laidAt,
    required this.totalCount,
    this.memo,
    this.incubationTemp,
    this.incubationHumidity,
    required this.hatches,
    this.notes = const [],
    required this.createdAt,
  });

  /// 산란일로부터 며칠째인가 (산란일 당일은 0).
  int get daysSinceLaid {
    final laid = DateTime(laidAt.year, laidAt.month, laidAt.day);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).difference(laid).inDays;
  }

  int get hatchedCount =>
      hatches.where((h) => h.status == HatchStatus.HATCHED).length;

  int get failedCount => hatches
      .where((h) =>
          h.status == HatchStatus.FAILED || h.status == HatchStatus.SLUG)
      .length;

  int get pendingCount =>
      hatches.where((h) => h.status == HatchStatus.PENDING).length;

  /// 부화했지만 아직 개체로 등록하지 않은 알 — 하단 등록 버튼의 개수.
  int get registerableCount => hatches
      .where((h) => h.status == HatchStatus.HATCHED && !h.isRegistered)
      .length;

  factory LayingRecord.fromJson(Map<String, dynamic> json) => LayingRecord(
        // 서버 키는 `layingId` / `eggCountTotal`(`LayingResponse`).
        id: (json['layingId'] ?? json['id']) as int,
        petId: (json['petId'] as int?) ?? 0,
        petName: json['petName'] as String?,
        speciesName: json['speciesName'] as String?,
        laidAt: DateTime.parse(json['laidAt'] as String),
        totalCount: ((json['eggCountTotal'] ?? json['totalCount']) as num).toInt(),
        memo: json['memo'] as String?,
        incubationTemp: (json['incubationTemp'] as num?)?.toDouble(),
        incubationHumidity: (json['incubationHumidity'] as num?)?.toDouble(),
        hatches: (json['hatches'] as List?)
                ?.map((e) => HatchRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notes: (json['notes'] as List?)
                ?.map((e) => LayingNote.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
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

  /// 기록 표시 텍스트.
  /// ⛔ 루틴 제목을 붙이지 않는다 — 캘린더·타임라인에 보이는 것은 **기록뿐**이고,
  /// 루틴은 그 기록이 생긴 계기일 뿐이다 (2026-10-07 확정).
  String get displayText => summary;
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
