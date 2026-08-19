enum NotificationType {
  ROUTINE_ALARM,      // 루틴 스케줄 알람
  COMMUNITY_COMMENT,  // 내 게시글에 댓글 (referenceId = commentId)
  COMMUNITY_LIKE,     // 내 게시글에 좋아요 (referenceId = postId)
  AI_CONSULTING,      // AI 개체 컨설팅 완료 (referenceId = petId)
  SYSTEM,             // 공지·점검 등 시스템 알림
}

/// SKIPPED = 수신 설정으로 푸시를 보내지 않음. 알림함에는 그대로 보인다
/// (끈 것은 폰이 울리는 것이지 무슨 일이 있었는지가 아니다).
enum NotificationStatus { PENDING, SENT, FAILED, READ, SKIPPED }

/// 알림 수신 설정.
///
/// 화면에는 한 목록이지만 저장 위치가 셋으로 갈린다 — 종류별 토글은 알림 설정 테이블,
/// [system]은 끌 수 없는 상수, [marketing]은 약관 동의 이력이다.
class NotificationPref {
  final bool routine;
  final bool comment;
  final bool postLike;
  final bool system; // 항상 true. 끌 수 없다
  final bool marketing;

  const NotificationPref({
    required this.routine,
    required this.comment,
    required this.postLike,
    required this.system,
    required this.marketing,
  });

  factory NotificationPref.fromJson(Map<String, dynamic> json) => NotificationPref(
        routine: json['routine'] as bool? ?? true,
        comment: json['comment'] as bool? ?? true,
        postLike: json['postLike'] as bool? ?? true,
        system: json['system'] as bool? ?? true,
        marketing: json['marketing'] as bool? ?? false,
      );
}

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
