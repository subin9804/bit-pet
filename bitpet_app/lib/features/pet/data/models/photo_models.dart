class PetPhoto {
  final int id;
  final String entityType; // PET / MEMO / MATING / LAYING
  final int entityId;
  final String url;         // presigned GET URL
  final String? tag;        // 사용자 태그 (탈피/식사/환경 등)
  final DateTime createdAt;

  const PetPhoto({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.url,
    this.tag,
    required this.createdAt,
  });

  factory PetPhoto.fromJson(Map<String, dynamic> json) => PetPhoto(
        id:         (json['photoId'] ?? json['id']) as int,
        entityType: json['entityType'] as String,
        entityId:   json['entityId']   as int,
        url:        json['url']        as String,
        tag:        (json['caption'] ?? json['tag']) as String?,
        createdAt:  DateTime.parse(json['createdAt'] as String),
      );
}
