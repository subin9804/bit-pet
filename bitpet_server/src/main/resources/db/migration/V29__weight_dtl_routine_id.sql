-- V29: weight_dtl에 routine_id 추가 (루틴 완료로 생성된 체중 기록 구분용)
ALTER TABLE weight_dtl
    ADD COLUMN routine_id BIGINT REFERENCES routine_mst(id) ON DELETE SET NULL;
