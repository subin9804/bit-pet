-- V9__routine_postpone.sql
-- 루틴 미루기 — 다음 예정일(next_due_at)을 사용자가 직접 앞당기거나 미룬 이력
--
-- 미루기는 '루틴 단위' 동작이다. 루틴에 연결된 모든 개체의 다음 예정일이 함께 밀린다.
-- 기록(routine_log_dtl)은 개체별 실행 원장이므로 여기에는 남기지 않는다 — 미룸은 실행이 아니라 알림 일정 변경.

ALTER TABLE routine_mst ADD COLUMN IF NOT EXISTS postponed_at   TIMESTAMPTZ;
ALTER TABLE routine_mst ADD COLUMN IF NOT EXISTS postponed_from DATE;

COMMENT ON COLUMN routine_mst.postponed_at   IS '마지막으로 미룬 시각 (없으면 미룬 적 없음)';
COMMENT ON COLUMN routine_mst.postponed_from IS '미루기 직전의 next_due_at — "9/16에서 미룸" 표시용';
