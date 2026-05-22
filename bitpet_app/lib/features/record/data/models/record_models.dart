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

// 홈 화면 최근 기록 통합 피드
class RecentRecord {
  final int id;
  final String petName;
  final String? colorCode;
  final String recordType; // FEEDING, WEIGHT, CLEANING, HEALTH
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

class HealthMemo {
  final int id;
  final int petId;
  final String? symptom;
  final String? treatment;
  final String? memo;
  final DateTime recordedAt;

  const HealthMemo({
    required this.id,
    required this.petId,
    this.symptom,
    this.treatment,
    this.memo,
    required this.recordedAt,
  });

  factory HealthMemo.fromJson(Map<String, dynamic> json) => HealthMemo(
        id: json['id'] as int,
        petId: json['petId'] as int,
        symptom: json['symptom'] as String?,
        treatment: json['treatment'] as String?,
        memo: json['memo'] as String?,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}
