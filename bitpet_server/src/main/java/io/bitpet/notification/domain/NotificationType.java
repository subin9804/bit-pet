package io.bitpet.notification.domain;

public enum NotificationType {
    ROUTINE_ALARM,      // 루틴 스케줄 알람 (RoutineScheduler 발송)
    COMMUNITY_COMMENT,  // 내 게시글에 댓글 (reference_id = comment_id)
    COMMUNITY_LIKE,     // 내 게시글에 좋아요 (reference_id = post_id)
    AI_CONSULTING,      // AI 개체 컨설팅 완료 (reference_id = pet_id)
    SYSTEM              // 공지·점검 등 시스템 알림
}
