// 05b 급여 기록 도메인 모델
// 공용 리치 컴포저(FeedFormData)와 상호 변환하여 size_label·ml·영양제까지 표현.

import '../food_catalog.dart';

class FeedItem {
  final String food;                    // 표시 라벨 (귀뚜라미 등) 또는 커스텀 텍스트
  final int amt;                        // 마릿수 (sizeCount 모드)
  final String? foodCode;               // API 코드(CRICKET 등). 없으면 라벨로 역산
  final String? sizeLabel;              // 크기/용량 라벨 (소/중/대, 소량 등)
  final double? mlAmount;               // ml 모드 급여량
  final FeedingSupplement? supplement;  // 영양제
  final bool isRefused;                 // 거식 — 먹이 정보 없이 "거부함"만 남는 기록

  const FeedItem({
    required this.food,
    required this.amt,
    this.foodCode,
    this.sizeLabel,
    this.mlAmount,
    this.supplement,
    this.isRefused = false,
  });

  /// 거식 기록 1건
  factory FeedItem.refused() => const FeedItem(food: '거식', amt: 0, isRefused: true);

  /// API 코드 (foodCode 우선, 없으면 라벨→코드 역산)
  String get code => foodCode ?? FoodType.codeForLabel(food);

  /// 간단 생성 (mock 시드 / 레거시 라벨 기반)
  factory FeedItem.simple({required String food, required int amt}) =>
      FeedItem(food: food, amt: amt);

  /// 공용 리치 폼 → FeedItem
  factory FeedItem.fromForm(FeedFormData f) {
    if (f.isRefused) return FeedItem.refused();
    final ft = f.foodType;
    final isCustom = ft?.isCustom ?? false;
    final label = isCustom ? (f.customText?.trim() ?? '직접입력') : (ft?.label ?? '');
    return FeedItem(
      food: label,
      amt: f.count ?? 0,
      foodCode: isCustom ? (f.customText?.trim() ?? 'CUSTOM') : ft?.code,
      sizeLabel: f.sizeLabel,
      mlAmount: f.useMl ? f.mlAmount : null,
      supplement: f.supplement,
    );
  }

  /// FeedItem → 공용 리치 폼
  FeedFormData toForm() {
    if (isRefused) return const FeedFormData(isRefused: true);
    final ft = FoodType.byCodeOrCustom(code);
    final isCustom = ft.isCustom;
    return FeedFormData(
      foodType: ft,
      count: amt > 0 ? amt : null,
      sizeLabel: sizeLabel,
      mlAmount: mlAmount,
      useMl: mlAmount != null,
      // 저장된 급여량이 칩 목록에 없으면 직접 적은 값 → 직접입력 모드로 되살린다
      useCustomAmount: sizeLabel != null &&
          ft.inputMode == FoodInputMode.volume &&
          !(ft.volumeOptions ?? const []).contains(sizeLabel),
      customText: isCustom ? food : null,
      supplement: supplement,
    );
  }

  /// 표시용 상세 문자열 (라벨 · 크기 · 마릿수 · ml · 영양제)
  String get detail {
    if (isRefused) return '거식';
    final s = toForm().summary;
    return s.isNotEmpty ? s : food;
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        food: json['food'] as String,
        amt: json['amt'] as int? ?? 0,
        foodCode: json['foodCode'] as String?,
        sizeLabel: json['sizeLabel'] as String?,
        mlAmount: (json['mlAmount'] as num?)?.toDouble(),
        isRefused: json['refused'] as bool? ?? false,
        supplement: json['supplement'] != null
            ? FeedingSupplement.values.firstWhere(
                (e) => e.name == json['supplement'],
                orElse: () => FeedingSupplement.OTHER)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'food': food,
        'amt': amt,
        if (foodCode != null) 'foodCode': foodCode,
        if (sizeLabel != null) 'sizeLabel': sizeLabel,
        if (mlAmount != null) 'mlAmount': mlAmount,
        if (supplement != null) 'supplement': supplement!.name,
        if (isRefused) 'refused': true,
      };

  FeedItem copyWith({
    String? food,
    int? amt,
    String? foodCode,
    String? sizeLabel,
    double? mlAmount,
    FeedingSupplement? supplement,
    bool? isRefused,
  }) =>
      FeedItem(
        food: food ?? this.food,
        amt: amt ?? this.amt,
        foodCode: foodCode ?? this.foodCode,
        sizeLabel: sizeLabel ?? this.sizeLabel,
        mlAmount: mlAmount ?? this.mlAmount,
        supplement: supplement ?? this.supplement,
        isRefused: isRefused ?? this.isRefused,
      );
}

class FeedSession {
  final String id;
  final String date; // "YYYY-MM-DD"
  final String time; // "HH:mm"
  final List<FeedItem> items;
  final String memo;

  const FeedSession({
    required this.id,
    required this.date,
    required this.time,
    required this.items,
    required this.memo,
  });

  factory FeedSession.fromJson(Map<String, dynamic> json) => FeedSession(
        id:    json['id']   as String,
        date:  json['date'] as String,
        time:  json['time'] as String? ?? '21:00',
        items: (json['items'] as List)
            .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        memo:  json['memo'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id':    id,
        'date':  date,
        'time':  time,
        'items': items.map((i) => i.toJson()).toList(),
        'memo':  memo,
      };

  int get totalAmt => items.fold(0, (s, i) => s + i.amt);

  FeedSession copyWith({
    String? date, String? time,
    List<FeedItem>? items, String? memo,
  }) =>
      FeedSession(
        id:    id,
        date:  date  ?? this.date,
        time:  time  ?? this.time,
        items: items ?? this.items,
        memo:  memo  ?? this.memo,
      );
}

// 편집 시트 상태 DTO
class FeedEditorState {
  final bool isEdit;
  final String? editId;
  final String date;
  final String time;
  final List<FeedItem> items;
  final String memo;

  const FeedEditorState({
    required this.isEdit,
    this.editId,
    required this.date,
    required this.time,
    required this.items,
    required this.memo,
  });

  FeedEditorState copyWith({
    String? date, String? time,
    List<FeedItem>? items, String? memo,
  }) =>
      FeedEditorState(
        isEdit: isEdit,
        editId: editId,
        date:   date  ?? this.date,
        time:   time  ?? this.time,
        items:  items ?? this.items,
        memo:   memo  ?? this.memo,
      );
}
