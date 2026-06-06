import 'package:flutter/foundation.dart';

// ── 입력 모드 ────────────────────────────────────────────────────────────────
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
  static const custom      = FoodType._(code:'CUSTOM',       label:'직접입력',  inputMode:FoodInputMode.custom);

  static const all = [cricket,mealworm,fruitFly,superfood,pellet,vegetables,frozenVege,frozenMouse,frozenRat,custom];

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

@immutable
class FeedFormData {
  final FoodType? foodType;
  final int?    count;       // sizeCount: 마릿수
  final String? sizeLabel;   // sizeCount / volume / mlOrVolume(volume sub)
  final double? mlAmount;    // mlOrVolume (ml sub)
  final bool    useMl;       // mlOrVolume 모드 전환 플래그
  final String? customText;  // custom
  final FeedingSupplement? supplement;
  final String  memo;

  const FeedFormData({
    this.foodType, this.count, this.sizeLabel,
    this.mlAmount, this.useMl=false,
    this.customText, this.supplement, this.memo='',
  });

  bool get isValid => foodType != null &&
      (foodType!.isCustom ? (customText?.trim().isNotEmpty ?? false) : true);

  String get summary {
    if (foodType == null) return '';
    if (foodType!.isCustom) return customText?.trim() ?? '';
    final p = <String>[foodType!.label];
    if (sizeLabel != null) p.add(sizeLabel!);
    if (count != null && count! > 0) p.add('${count}마리');
    if (mlAmount != null && mlAmount! > 0) {
      final s = mlAmount! % 1 == 0 ? mlAmount!.toInt().toString() : mlAmount!.toStringAsFixed(1);
      p.add('${s}ml');
    }
    return p.join(' · ');
  }

  FeedFormData copyWith({
    FoodType? foodType,
    Object? count=_nil, Object? sizeLabel=_nil, Object? mlAmount=_nil,
    bool? useMl,
    Object? customText=_nil, Object? supplement=_nil,
    String? memo,
  }) => FeedFormData(
    foodType:    foodType   ?? this.foodType,
    count:       count      == _nil ? this.count      : count      as int?,
    sizeLabel:   sizeLabel  == _nil ? this.sizeLabel  : sizeLabel  as String?,
    mlAmount:    mlAmount   == _nil ? this.mlAmount   : mlAmount   as double?,
    useMl:       useMl      ?? this.useMl,
    customText:  customText == _nil ? this.customText : customText as String?,
    supplement:  supplement == _nil ? this.supplement : supplement as FeedingSupplement?,
    memo:        memo       ?? this.memo,
  );

  Map<String, dynamic> toApiMap({DateTime? fedAt}) {
    if (foodType == null) return {};
    final m = <String, dynamic>{};
    m['foodType'] = foodType!.isCustom ? (customText?.trim() ?? '') : foodType!.code;

    switch (foodType!.inputMode) {
      case FoodInputMode.sizeCount:
        if (count != null && count! > 0) { m['amount'] = count!.toDouble(); m['unit'] = 'PIECE'; }
        if (sizeLabel != null) m['sizeLabel'] = sizeLabel;
      case FoodInputMode.mlOrVolume:
        if (useMl && mlAmount != null && mlAmount! > 0) { m['amount'] = mlAmount; m['unit'] = 'ML'; }
        else if (!useMl && sizeLabel != null) m['sizeLabel'] = sizeLabel;
      case FoodInputMode.volume:
        if (sizeLabel != null) m['sizeLabel'] = sizeLabel;
      case FoodInputMode.custom:
        break;
    }
    if (supplement != null) m['supplement'] = supplement!.name;
    if (memo.trim().isNotEmpty) m['memo'] = memo.trim();
    if (fedAt != null) m['fedAt'] = fedAt.toIso8601String();
    return m;
  }
}
