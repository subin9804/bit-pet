/// NFC 태그 이름표 모델.
///
/// 태그는 자기 코드만 가지고 출고되고, 개체와의 연결은 서버 DB에만 존재한다.
/// 앱은 NFC를 읽지도 쓰지도 않는다 — OS가 URL을 열어주고 앱은 딥링크만 받는다.
library;

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
