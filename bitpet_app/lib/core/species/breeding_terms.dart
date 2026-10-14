/// 종 대분류에 따라 달라지는 번식 용어의 **단일 소스**.
///
/// 포유류는 알을 낳지 않는다 — 산란이 아니라 출산이고, 해칭일이 아니라 출생일이다.
/// 라벨을 화면마다 흩어 두면 한 군데가 빠지는데, 그 한 군데가 제일 눈에 띈다
/// (2026-10-14 사용자 지시: "포유류 개체 전역").
///
/// ⛔ 화면에서 `category == 'M'` 같은 비교를 직접 하지 말 것. 판정을 여기 한 곳에만 두면
/// 나중에 조류·어류가 들어와도 이 파일만 고친다.
library;

class BreedingTerms {
  /// 새끼를 낳는 종인가.
  final bool isMammal;

  const BreedingTerms._(this.isMammal);

  /// 파충류·양서류 — 산란/해칭.
  static const oviparous = BreedingTerms._(false);

  /// 포유류 — 출산/출생.
  static const viviparous = BreedingTerms._(true);

  /// 서버의 `speciesCategory`(R=파충류 / A=양서류 / M=포유류)로 용어를 고른다.
  ///
  /// ⚠️ 서버 `species_cd.category` 는 `CHAR(2)` 라 공백이 붙은 `'M '` 이 될 수 있다.
  /// 응답 DTO 가 이미 trim 해서 내리지만(`SpeciesCd.normalizedCategory`), 구버전 서버나
  /// 로컬 캐시를 거친 값이 섞일 수 있어 여기서 한 번 더 떼어낸다.
  static BreedingTerms of(String? speciesCategory) =>
      speciesCategory?.trim().toUpperCase() == categoryMammal
          ? viviparous
          : oviparous;

  static const categoryReptile = 'R';
  static const categoryAmphibian = 'A';
  static const categoryMammal = 'M';

  /// 기록 종류 이름 — '산란' / '출산'
  String get laying => isMammal ? '출산' : '산란';

  /// 날짜 필드 라벨 — '산란일' / '출산일'
  String get layingDate => isMammal ? '출산일' : '산란일';

  /// 낳은 것 하나 — '알' / '새끼'
  String get egg => isMammal ? '새끼' : '알';

  /// 수량 입력 라벨 — '알 총 개수' / '새끼 수'
  String get eggCountLabel => isMammal ? '새끼 수' : '알 총 개수';

  /// 수량 단위 — '개' / '마리'
  String get eggUnit => isMammal ? '마리' : '개';

  /// 태어난 날 라벨 — '해칭일' / '출생일'
  String get hatchDate => isMammal ? '출생일' : '해칭일';

  /// 태어난 일 자체 — '해칭' / '출생'
  String get hatch => isMammal ? '출생' : '해칭';

  /// FAB 기록 종류 박스의 부제 — 포유류는 인큐베이션 값을 받지 않는다.
  String get layingHint => isMammal ? '새끼 수' : '알 수·인큐베이션';
}
