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
  ownedByOther;

  static TagStatus fromServer(String? value) => switch (value) {
        'LINKED' => TagStatus.linked,
        'OWNED_BY_OTHER' => TagStatus.ownedByOther,
        _ => TagStatus.unlinked,
      };
}

/// 태그를 스캔했을 때 앱이 수행할 기본 동작.
/// 제품 라인업(기본형/급여용/체중용)은 이 값으로만 구분한다 — 굽는 URL은 동일.
enum TagAction {
  petDetail('PET_DETAIL', '개체 상세만'),
  recordFeeding('RECORD_FEEDING', '급여 기록 바로 열기'),
  recordWeight('RECORD_WEIGHT', '체중 기록 바로 열기');

  final String serverValue;
  final String label;
  const TagAction(this.serverValue, this.label);

  static TagAction fromServer(String? value) => TagAction.values.firstWhere(
        (a) => a.serverValue == value,
        orElse: () => TagAction.petDetail,
      );

  /// 개체 상세로 이동할 때 자동으로 열 기록 종류 (FabRecordSheet의 typeId).
  /// null이면 시트를 열지 않는다.
  String? get recordTypeId => switch (this) {
        TagAction.recordFeeding => 'feed',
        TagAction.recordWeight => 'scale',
        TagAction.petDetail => null,
      };
}

/// GET /api/v1/tags/{tagCd} 응답
class TagResolveResult {
  final TagStatus status;
  final String tagCd;
  final int? petId;
  final String? petNm;
  final TagAction defaultAction;

  const TagResolveResult({
    required this.status,
    required this.tagCd,
    this.petId,
    this.petNm,
    this.defaultAction = TagAction.petDetail,
  });

  factory TagResolveResult.fromJson(Map<String, dynamic> json) {
    return TagResolveResult(
      status: TagStatus.fromServer(json['status'] as String?),
      tagCd: json['tagCd'] as String? ?? '',
      petId: json['petId'] as int?,
      petNm: json['petNm'] as String?,
      defaultAction: TagAction.fromServer(json['defaultActionCd'] as String?),
    );
  }
}

/// GET /api/v1/tags/my 응답 — 마이페이지 태그 관리용
class MyTag {
  final String tagCd;
  final int? petId;
  final String? petNm;
  final TagAction defaultAction;
  final DateTime? linkedAt;
  final int scanCnt;
  final DateTime? lastScanAt;

  const MyTag({
    required this.tagCd,
    this.petId,
    this.petNm,
    this.defaultAction = TagAction.petDetail,
    this.linkedAt,
    this.scanCnt = 0,
    this.lastScanAt,
  });

  factory MyTag.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? v) => v == null ? null : DateTime.tryParse(v)?.toLocal();
    return MyTag(
      tagCd: json['tagCd'] as String? ?? '',
      petId: json['petId'] as int?,
      petNm: json['petNm'] as String?,
      defaultAction: TagAction.fromServer(json['defaultActionCd'] as String?),
      linkedAt: parse(json['linkedAt'] as String?),
      scanCnt: json['scanCnt'] as int? ?? 0,
      lastScanAt: parse(json['lastScanAt'] as String?),
    );
  }
}
