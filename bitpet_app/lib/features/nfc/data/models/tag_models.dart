/// NFC 태그 이름표 모델.
///
/// 태그는 자기 코드만 가지고 출고되고, 개체와의 연결은 서버 DB에만 존재한다.
///
/// 태그를 읽는 경로는 둘이다.
///  1. **딥링크** — 앱이 꺼져 있거나 배경일 때. OS가 `https://tailog.me/t/{tagCd}` 를 열어준다
///  2. **앱 내 스캔** — `core/nfc/NfcPetScanSheet`. 개체를 고르는 자리에서 직접 NDEF를 읽는다.
///     시트가 떠 있는 동안은 리더 모드로 NFC를 선점해 1번 경로(딥링크)가 화면을 갈아엎지 못하게 한다
library;

import '../../../pet/data/models/pet_models.dart';

/// 태그 스캔 결과 상태. 이 값으로만 분기한다.
enum TagStatus {
  /// 아직 어떤 개체와도 연결되지 않음 → 개체 선택 모달
  unlinked,

  /// 내(또는 내가 사육 중인) 개체와 연결됨 → 개체 상세 + 기본 동작
  linked,

  /// 남의 개체와 연결됨 → 안내만
  ownedByOther,

  /// 분실·복제로 차단된 태그 → "사용 중지된 태그" 안내.
  /// 없는 코드(404)와 다르다 — 실재하지만 서비스가 막은 것이다.
  revoked;

  static TagStatus fromServer(String? value) => switch (value) {
        'LINKED' => TagStatus.linked,
        'OWNED_BY_OTHER' => TagStatus.ownedByOther,
        'REVOKED' => TagStatus.revoked,
        _ => TagStatus.unlinked,
      };
}

/// 태그 한 장의 유통 상태 (서버 nfc_tag_mst.status).
enum TagStockStatus {
  stock,
  sold,
  bound,
  revoked;

  static TagStockStatus fromServer(String? value) => switch (value) {
        'STOCK' => TagStockStatus.stock,
        'SOLD' => TagStockStatus.sold,
        'REVOKED' => TagStockStatus.revoked,
        _ => TagStockStatus.bound,
      };
}

/// GET /api/v1/tags/{tagCd} 응답
class TagResolveResult {
  final TagStatus status;
  final String tagCd;
  final int? petId;
  final String? petNm;

  const TagResolveResult({
    required this.status,
    required this.tagCd,
    this.petId,
    this.petNm,
  });

  factory TagResolveResult.fromJson(Map<String, dynamic> json) {
    return TagResolveResult(
      status: TagStatus.fromServer(json['status'] as String?),
      tagCd: json['tagCd'] as String? ?? '',
      petId: json['petId'] as int?,
      petNm: json['petNm'] as String?,
    );
  }
}

/// GET /api/v1/nfc/tags/{tagCd}/resolve 응답.
///
/// [TagResolveResult]와 달리 개체 정보를 카드로 함께 받는다 — 스캔 시트가 "이 개체가 맞나요?"를
/// 그 자리에서 보여줘야 하는데, 개체 상세를 다시 부르면 남의 개체에서 403이 난다.
///
/// **남의 개체일 때 필드를 잘라내는 건 서버다.** 소유자 정보([PetCard.owner])는 응답에
/// 아예 담겨 오지 않고, 사육기록·체중·커뮤니티 활동은 [PetCard] 자체에 없다.
/// 여기서 추가로 숨길 것도 없고, 숨겨서도 안 된다 — 숨김은 응답을 까 보면 무너진다.
class NfcScanResult {
  final TagStatus status;
  final String tagCd;

  /// LINKED / OWNED_BY_OTHER 일 때만. UNLINKED·REVOKED 면 null
  final PetCard? pet;

  const NfcScanResult({required this.status, required this.tagCd, this.pet});

  /// 내가 사육하는 개체에 붙은 태그인지
  bool get isMine => status == TagStatus.linked;

  factory NfcScanResult.fromJson(Map<String, dynamic> json) => NfcScanResult(
        status: TagStatus.fromServer(json['status'] as String?),
        tagCd: json['tagCd'] as String? ?? '',
        pet: json['pet'] == null
            ? null
            : PetCard.fromJson(json['pet'] as Map<String, dynamic>),
      );
}

/// GET /api/v1/tags/my 응답 — 마이페이지 태그 관리용
class MyTag {
  final String tagCd;
  final int? petId;
  final String? petNm;
  final DateTime? linkedAt;
  final TagStockStatus status;

  /// 칩 세대. NTAG203은 패스워드 보호가 불가능해 락 없이 출고된다
  final String? chipType;

  const MyTag({
    required this.tagCd,
    this.petId,
    this.petNm,
    this.linkedAt,
    this.status = TagStockStatus.bound,
    this.chipType,
  });

  factory MyTag.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? v) => v == null ? null : DateTime.tryParse(v)?.toLocal();
    return MyTag(
      tagCd: json['tagCd'] as String? ?? '',
      petId: json['petId'] as int?,
      petNm: json['petNm'] as String?,
      linkedAt: parse(json['linkedAt'] as String?),
      status: TagStockStatus.fromServer(json['status'] as String?),
      chipType: json['chipType'] as String?,
    );
  }
}
