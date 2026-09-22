class PetPhoto {
  final int id;
  final String entityType; // PET / MEMO / MATING / LAYING
  final int entityId;
  final String url;         // presigned GET URL (원본)
  /// 축소본(짧은 변 512px) URL. **없을 수 있다** — 썸네일을 쓰기 시작하기 전에 올라간
  /// 사진과 구버전 앱이 올린 사진에는 없다(기존 사진을 백필하지 않았다). [displayUrl] 참고.
  final String? thumbnailUrl;
  final String? tag;        // 사용자 태그 (탈피/식사/환경 등)
  final DateTime createdAt;

  const PetPhoto({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.url,
    this.thumbnailUrl,
    this.tag,
    required this.createdAt,
  });

  /// 목록·그리드·아바타처럼 작게 그리는 자리에서 쓸 URL. 원본은 확대 뷰어에서만 쓴다.
  String get displayUrl => thumbnailUrl ?? url;

  factory PetPhoto.fromJson(Map<String, dynamic> json) => PetPhoto(
        id:           (json['photoId'] ?? json['id']) as int,
        entityType:   json['entityType'] as String,
        entityId:     json['entityId']   as int,
        url:          json['url']        as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        tag:          (json['caption'] ?? json['tag']) as String?,
        createdAt:    DateTime.parse(json['createdAt'] as String),
      );
}
