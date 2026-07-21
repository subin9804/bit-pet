-- =============================================================================
-- V47: routine_log_dtl 정규화
--   · 완료 이벤트(routine_log_dtl)와 실제 기록(feeding/weight/cleaning/memo_dtl)을
--     routine_log_id 로 명시 연결 (기존 (routine_id, pet_id, 시각) 암묵 매칭 제거).
--   · 중복이던 routine_log_dtl.memo 와 미사용 extra_data 컬럼 드롭.
--     완료 메모는 각 dtl(feeding/weight/cleaning) 에, 미완료·커스텀 메모는 memo_dtl 에 저장.
-- =============================================================================

ALTER TABLE feeding_dtl  ADD COLUMN routine_log_id BIGINT;
ALTER TABLE weight_dtl   ADD COLUMN routine_log_id BIGINT;
ALTER TABLE cleaning_dtl ADD COLUMN routine_log_id BIGINT;
ALTER TABLE memo_dtl     ADD COLUMN routine_log_id BIGINT;

-- 백필: 루틴 완료로 생성된 기존 dtl 을 같은 (routine_id, pet_id, 시각) 로그에 연결
UPDATE feeding_dtl d SET routine_log_id = l.id
FROM routine_log_dtl l
WHERE d.routine_id IS NOT NULL
  AND d.routine_id = l.routine_id AND d.pet_id = l.pet_id
  AND d.fed_at = l.executed_at;

UPDATE weight_dtl d SET routine_log_id = l.id
FROM routine_log_dtl l
WHERE d.routine_id IS NOT NULL
  AND d.routine_id = l.routine_id AND d.pet_id = l.pet_id
  AND d.measured_at = l.executed_at;

UPDATE cleaning_dtl d SET routine_log_id = l.id
FROM routine_log_dtl l
WHERE d.routine_id IS NOT NULL
  AND d.routine_id = l.routine_id AND d.pet_id = l.pet_id
  AND d.cleaned_at = l.executed_at;

UPDATE memo_dtl d SET routine_log_id = l.id
FROM routine_log_dtl l
WHERE d.routine_id IS NOT NULL
  AND d.routine_id = l.routine_id AND d.pet_id = l.pet_id
  AND d.logged_at = l.executed_at;

CREATE INDEX idx_feeding_dtl_routine_log  ON feeding_dtl  (routine_log_id);
CREATE INDEX idx_weight_dtl_routine_log   ON weight_dtl   (routine_log_id);
CREATE INDEX idx_cleaning_dtl_routine_log ON cleaning_dtl (routine_log_id);
CREATE INDEX idx_memo_dtl_routine_log     ON memo_dtl     (routine_log_id);

ALTER TABLE routine_log_dtl DROP COLUMN memo;
ALTER TABLE routine_log_dtl DROP COLUMN extra_data;
