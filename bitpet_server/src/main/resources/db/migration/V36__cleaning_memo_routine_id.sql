-- V36: cleaning_dtl / memo_dtl 에 routine_id 추가
-- 청소·CUSTOM 루틴 완료 기록을 각 dtl 테이블에 저장하기 위한 FK 컬럼.
-- ON DELETE SET NULL → 루틴을 삭제해도 기록(청소/메모)은 보존, routine_id만 null.

ALTER TABLE cleaning_dtl
    ADD COLUMN routine_id BIGINT NULL
        CONSTRAINT fk_cleaning_dtl_routine REFERENCES routine_mst(id) ON DELETE SET NULL;

CREATE INDEX idx_cleaning_dtl_routine
    ON cleaning_dtl(routine_id)
    WHERE routine_id IS NOT NULL AND deleted_at IS NULL;

ALTER TABLE memo_dtl
    ADD COLUMN routine_id BIGINT NULL
        CONSTRAINT fk_memo_dtl_routine REFERENCES routine_mst(id) ON DELETE SET NULL;

CREATE INDEX idx_memo_dtl_routine
    ON memo_dtl(routine_id)
    WHERE routine_id IS NOT NULL AND deleted_at IS NULL;
