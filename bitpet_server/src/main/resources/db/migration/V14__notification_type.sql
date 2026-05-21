-- V14: notification_log_dtl 알림 타입 확장
-- alarm_mst를 되살리는 대신 notification_log_dtl에 notification_type + reference_id 추가.
-- 루틴 알람 외 커뮤니티(댓글·좋아요), AI 컨설팅, 시스템 알림을 단일 테이블에서 관리.
--
-- notification_type 기준 컬럼 활용 규칙:
--   ROUTINE_ALARM    : routine_id, pet_id(대표), pet_count 사용
--   COMMUNITY_COMMENT: reference_id = comment_id, pet_id/routine_id NULL
--   COMMUNITY_LIKE   : reference_id = post_id,    pet_id/routine_id NULL
--   AI_CONSULTING    : reference_id = pet_id (pet_id 컬럼 중복 활용도 가능)
--   SYSTEM           : 모두 NULL

ALTER TABLE notification_log_dtl
    ADD COLUMN notification_type VARCHAR(30) NOT NULL DEFAULT 'ROUTINE_ALARM',
    ADD COLUMN reference_id      BIGINT;

-- 기존 데이터는 모두 ROUTINE_ALARM 타입으로 간주 (DEFAULT로 처리됨)

-- 타입별 조회용 인덱스
CREATE INDEX idx_notification_log_type ON notification_log_dtl (user_id, notification_type, sent_at DESC);
