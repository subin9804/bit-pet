import '../../features/pet/data/models/pet_models.dart';

/// 태그로 찾아낸 개체 한 마리 — [NfcPetScanSheet]의 반환값.
///
/// [PetCard]를 그대로 감싼다. 카드는 이미 "남에게 보여도 되는 전부"로 설계된 모델이라
/// 스캔 결과에 필요한 필드(개체명·종·모프·성별·해칭일)와 정확히 겹치고, 개체 선택을 받는
/// 쪽(가계도 부모 선택 등)이 이미 [PetCard]로 동작한다 — 새 모델을 만들면 변환만 늘어난다.
///
/// [tagCd]를 함께 들고 다니는 이유는 호출부가 "무엇으로 골랐는지"를 알아야 하기 때문이다.
/// 목록에서 고른 개체와 태그로 찾은 개체는 같은 개체여도 사용자에게 보여줄 말이 다르다.
class PetSummary {
  /// 이 개체를 찾아낸 태그 코드 (대문자 정규화됨)
  final String tagCd;
  final PetCard card;

  const PetSummary({required this.tagCd, required this.card});

  int get petId => card.petId;
  String get name => card.name;

  /// 내가 사육하는 개체인지. false면 남의 개체를 스캔한 것이고,
  /// 서버가 소유자 정보를 뺀 카드만 내려보냈다.
  bool get isMine => card.isKeeper;
}
