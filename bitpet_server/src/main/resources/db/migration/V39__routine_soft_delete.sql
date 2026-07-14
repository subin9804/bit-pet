-- V39: routine_mst soft delete 전환 — 루틴(알림)과 기록의 분리
-- 루틴을 삭제해도 실행 기록(routine_log_dtl)과 파생 기록(feeding/weight/cleaning/memo dtl)은
-- 보존되어야 한다. hard delete 시 routine_log_dtl FK(ON DELETE CASCADE)가 기록을 함께
-- 지우므로, soft delete로 전환해 cascade가 발동하지 않게 한다.

ALTER TABLE routine_mst ADD COLUMN deleted_at TIMESTAMPTZ NULL;

COMMENT ON COLUMN routine_mst.deleted_at IS 'soft delete 시각 (NULL = 활성). 삭제해도 기록 테이블은 보존';
