-- =============================================================================
-- V35: 루틴 시작일 보존 (routine_mst.start_date)
--   - nextDueAt은 완료 시마다 전진하므로 원래 시작일을 역산할 수 없음
--   - 캘린더에서 "시작일 이후만 예정 표시"하려면 시작일을 고정 보존해야 함
-- =============================================================================

ALTER TABLE routine_mst ADD COLUMN start_date DATE;

-- 기존 루틴 백필 — 생성일(Seoul 날짜)을 시작일 하한으로 사용
-- (정확한 시작일이 보존돼 있지 않으므로 created_at 기준 근사)
UPDATE routine_mst
SET start_date = (created_at AT TIME ZONE 'Asia/Seoul')::date
WHERE start_date IS NULL;

COMMENT ON COLUMN routine_mst.start_date IS 'v6: 루틴 시작일(고정). nextDueAt 초기값과 동일하나 완료해도 불변 — 캘린더 표시 하한';
