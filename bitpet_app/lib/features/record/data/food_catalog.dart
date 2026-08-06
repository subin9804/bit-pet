import 'package:flutter/foundation.dart';

// ── 입력 모드 ────────────────────────────────────────────────────────────────
// custom = 이름을 직접 적는 먹이. 이름만 다를 뿐 사이즈·마릿수는 sizeCount 와 똑같이 받는다.
enum FoodInputMode { sizeCount, mlOrVolume, volume, custom }

// ── 먹이 종류 ────────────────────────────────────────────────────────────────
@immutable
class FoodType {
  final String code;
  final String label;
  final FoodInputMode inputMode;
  final List<String>? sizeOptions;
  final List<String>? volumeOptions;

  const FoodType._({
    required this.code,
    required this.label,
    required this.inputMode,
    this.sizeOptions,
    this.volumeOptions,
  });

  bool get isCustom => inputMode == FoodInputMode.custom;

  static const _insectSizes = ['극소', '소', '중', '대'];
  static const _mouseSizes  = ['핑키', '퍼지', '하퍼', '성체'];
  static const _volLabels   = ['극소량', '소량', '중량', '대량'];

  static const cricket     = FoodType._(code:'CRICKET',      label:'귀뚜라미',  inputMode:FoodInputMode.sizeCount,  sizeOptions:_insectSizes);
  static const mealworm    = FoodType._(code:'MEALWORM',     label:'밀웜',      inputMode:FoodInputMode.sizeCount,  sizeOptions:_insectSizes);
  static const fruitFly    = FoodType._(code:'FRUIT_FLY',    label:'초파리',    inputMode:FoodInputMode.sizeCount,  sizeOptions:_insectSizes);
  static const superfood   = FoodType._(code:'SUPERFOOD',    label:'슈퍼푸드',  inputMode:FoodInputMode.mlOrVolume, volumeOptions:_volLabels);
  static const pellet      = FoodType._(code:'PELLET',       label:'사료',      inputMode:FoodInputMode.volume,     volumeOptions:_volLabels);
  static const vegetables  = FoodType._(code:'VEGETABLES',   label:'야채/과일', inputMode:FoodInputMode.volume,     volumeOptions:_volLabels);
  static const frozenVege  = FoodType._(code:'FROZEN_VEGE',  label:'냉짱',      inputMode:FoodInputMode.volume,     volumeOptions:_volLabels);
  static const frozenMouse = FoodType._(code:'FROZEN_MOUSE', label:'마우스',    inputMode:FoodInputMode.sizeCount,  sizeOptions:_mouseSizes);
  static const frozenRat   = FoodType._(code:'FROZEN_RAT',   label:'래트',      inputMode:FoodInputMode.sizeCount,  sizeOptions:_mouseSizes);
  static const custom      = FoodType._(code:'CUSTOM',       label:'직접입력',  inputMode:FoodInputMode.custom,     sizeOptions:_insectSizes);

  static const all = [cricket,mealworm,fruitFly,superfood,pellet,vegetables,frozenVege,frozenMouse,frozenRat,custom];

  /// API 코드(CRICKET 등) → 한국어 라벨. 매핑 없으면 code 그대로 반환.
  static String labelForCode(String code) {
    for (final f in all) { if (f.code == code) return f.label; }
    return code;
  }

  /// 한국어 라벨(귀뚜라미 등) → API 코드. 매핑 없으면 label 그대로 반환.
  static String codeForLabel(String label) {
    for (final f in all) { if (f.label == label) return f.code; }
    return label;
  }

  /// API 코드로 FoodType 조회. 카탈로그에 없으면 custom(직접입력) 반환.
  static FoodType byCodeOrCustom(String code) {
    for (final f in all) { if (f.code == code) return f; }
    return custom;
  }

  @override bool operator==(Object o) => o is FoodType && o.code == code;
  @override int get hashCode => code.hashCode;
}

// ── 영양제 ───────────────────────────────────────────────────────────────────
enum FeedingSupplement {
  CALCIUM, PROBIOTIC, VITAMIN, OTHER;
  String get label => switch(this){
    CALCIUM=>'칼슘', PROBIOTIC=>'유산균', VITAMIN=>'비타민', OTHER=>'기타',
  };
}

// ── 폼 상태 ──────────────────────────────────────────────────────────────────
const _nil = Object();

/// 급여량 자유 입력 최대 길이 — 서버 `feeding_dtl.size_label` 이 VARCHAR(10) 이다.
const int kAmountTextMaxLength = 10;

@immutable
class FeedFormData {
  final FoodType? foodType;
  final int?    count;       // sizeCount / custom: 마릿수
  final String? sizeLabel;   // sizeCount / volume / mlOrVolume(volume sub) / 자유 입력 급여량
  final double? mlAmount;    // mlOrVolume (ml sub)
  final bool    useMl;       // mlOrVolume 모드 전환 플래그
  final bool    useCustomAmount; // volume: 칩 대신 급여량을 직접 적는 모드
  final String? customText;  // custom: 먹이 이름
  final FeedingSupplement? supplement;
  final String  memo;

  /// 거식 — 먹이를 거부한 기록. 켜지면 먹이 정보는 전부 무시되고 메모만 남는다.
  final bool isRefused;

  const FeedFormData({
    this.foodType, this.count, this.sizeLabel,
    this.mlAmount, this.useMl=false, this.useCustomAmount=false,
    this.customText, this.supplement, this.memo='',
    this.isRefused=false,
  });

  bool get isValid {
    if (isRefused) return true; // 메모조차 선택 — 거식했다는 사실만으로 기록이 된다
    return foodType != null &&
        (foodType!.isCustom ? (customText?.trim().isNotEmpty ?? false) : true);
  }

  String get summary {
    if (isRefused) return '거식';
    if (foodType == null) return '';
    // 직접입력도 이름만 다를 뿐 사이즈·마릿수는 똑같이 붙는다
    final head = foodType!.isCustom ? (customText?.trim() ?? '') : foodType!.label;
    if (head.isEmpty) return '';
    final p = <String>[head];
    if (sizeLabel != null) p.add(sizeLabel!);
    if (count != null && count! > 0) p.add('${count}마리');
    if (mlAmount != null && mlAmount! > 0) {
      final s = mlAmount! % 1 == 0 ? mlAmount!.toInt().toString() : mlAmount!.toStringAsFixed(1);
      p.add('${s}ml');
    }
    if (supplement != null) p.add(supplement!.label);
    return p.join(' · ');
  }

  FeedFormData copyWith({
    FoodType? foodType,
    Object? count=_nil, Object? sizeLabel=_nil, Object? mlAmount=_nil,
    bool? useMl, bool? useCustomAmount,
    Object? customText=_nil, Object? supplement=_nil,
    String? memo, bool? isRefused,
  }) => FeedFormData(
    foodType:    foodType   ?? this.foodType,
    count:       count      == _nil ? this.count      : count      as int?,
    sizeLabel:   sizeLabel  == _nil ? this.sizeLabel  : sizeLabel  as String?,
    mlAmount:    mlAmount   == _nil ? this.mlAmount   : mlAmount   as double?,
    useMl:       useMl      ?? this.useMl,
    useCustomAmount: useCustomAmount ?? this.useCustomAmount,
    customText:  customText == _nil ? this.customText : customText as String?,
    supplement:  supplement == _nil ? this.supplement : supplement as FeedingSupplement?,
    memo:        memo       ?? this.memo,
    isRefused:   isRefused  ?? this.isRefused,
  );

  /// 서버 급여 항목({foodType, amount, unit, sizeLabel, supplement, refused}) → 폼 데이터 복원
  factory FeedFormData.fromApiMap(Map<String, dynamic> m) {
    // 거식이면 서버가 먹이 정보를 아예 안 준다 — 메모만 살린다
    if (m['refused'] == true) {
      return FeedFormData(isRefused: true, memo: (m['memo'] as String?) ?? '');
    }
    final code   = m['foodType'] as String?;
    final ft     = code == null ? null : FoodType.byCodeOrCustom(code);
    final unit   = m['unit'] as String?;
    final amount = (m['amount'] as num?)?.toDouble();
    final isMl   = unit == 'ML';
    final size   = m['sizeLabel'] as String?;
    final supRaw = m['supplement'] as String?;
    return FeedFormData(
      foodType:   ft,
      count:      (!isMl && amount != null) ? amount.toInt() : null,
      sizeLabel:  size,
      mlAmount:   isMl ? amount : null,
      useMl:      isMl,
      // 저장된 급여량이 칩 목록에 없으면 직접 적은 값이다 → 직접입력 모드로 되살린다
      useCustomAmount: size != null &&
          ft != null &&
          ft.inputMode == FoodInputMode.volume &&
          !(ft.volumeOptions ?? const []).contains(size),
      customText: (ft != null && ft.isCustom) ? code : null,
      memo:       (m['memo'] as String?) ?? '',
      supplement: supRaw == null
          ? null
          : FeedingSupplement.values.firstWhere(
              (s) => s.name == supRaw,
              orElse: () => FeedingSupplement.values.first),
    );
  }

  Map<String, dynamic> toApiMap({DateTime? fedAt}) {
    final m = <String, dynamic>{};
    // 거식은 먹이 정보 없이 메모만 — 서버도 food_type 이 NULL 인 행만 받는다
    if (isRefused) {
      m['refused'] = true;
      if (memo.trim().isNotEmpty) m['memo'] = memo.trim();
      if (fedAt != null) m['fedAt'] = fedAt.toUtc().toIso8601String();
      return m;
    }
    if (foodType == null) return {};
    m['refused']  = false;
    m['foodType'] = foodType!.isCustom ? (customText?.trim() ?? '') : foodType!.code;

    switch (foodType!.inputMode) {
      // 직접입력도 사이즈·마릿수를 그대로 받는다 (이름만 사용자가 적는 것)
      case FoodInputMode.sizeCount:
      case FoodInputMode.custom:
        if (count != null && count! > 0) { m['amount'] = count!.toDouble(); m['unit'] = 'PIECE'; }
        if (sizeLabel != null) m['sizeLabel'] = sizeLabel;
      case FoodInputMode.mlOrVolume:
        if (useMl && mlAmount != null && mlAmount! > 0) { m['amount'] = mlAmount; m['unit'] = 'ML'; }
        else if (!useMl && sizeLabel != null) m['sizeLabel'] = sizeLabel;
      case FoodInputMode.volume:
        // 칩이든 직접 적은 값이든 저장 위치는 같다
        if (sizeLabel != null && sizeLabel!.trim().isNotEmpty) m['sizeLabel'] = sizeLabel!.trim();
    }
    if (supplement != null) m['supplement'] = supplement!.name;
    if (memo.trim().isNotEmpty) m['memo'] = memo.trim();
    if (fedAt != null) m['fedAt'] = fedAt.toUtc().toIso8601String();
    return m;
  }
}
