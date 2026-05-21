enum NotificationType {
  ROUTINE_ALARM,      // 루틴 스케줄 알람
  COMMUNITY_COMMENT,  // 내 게시글에 댓글 (referenceId = commentId)
  COMMUNITY_LIKE,     // 내 게시글에 좋아요 (referenceId = postId)
  AI_CONSULTING,      // AI 개체 컨설팅 완료 (referenceId = petId)
  SYSTEM,             // 공지·점검 등 시스템 알림
}

enum NotificationStatus { PENDING, SENT, FAILED, READ }

class NotificationLog {
  final int id;
  final NotificationType notificationType;
  final int? petId;
  final int? routineId;
  final int? referenceId;
  final String title;
  final String body;
  final DateTime sentAt;
  final NotificationStatus status;

  const NotificationLog({
    required this.id,
    required this.notificationType,
    this.petId,
    this.routineId,
    this.referenceId,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.status,
  });

  bool get isRead => status == NotificationStatus.READ;

  factory NotificationLog.fromJson(Map<String, dynamic> json) => NotificationLog(
        id: json['id'] as int,
        notificationType: NotificationType.values.firstWhere(
          (e) => e.name == json['notificationType'],
          orElse: () => NotificationType.SYSTEM,
        ),
        petId: json['petId'] as int?,
        routineId: json['routineId'] as int?,
        referenceId: json['referenceId'] as int?,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        sentAt: DateTime.parse(json['sentAt'] as String),
        status: NotificationStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => NotificationStatus.SENT,
        ),
      );
}
