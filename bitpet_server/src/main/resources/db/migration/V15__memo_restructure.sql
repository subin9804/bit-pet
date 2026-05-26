-- =============================================================================
-- V15: health_memo_dtl → memo_dtl 리네이밍 + 컬럼 재편
-- 기획서 v5 / ERD v3 반영: 자유 텍스트 + 태그 시스템으로 전환
-- NOTE: sync_version / client_id / client_change_id 는 V10에서 이미 추가됨
-- =============================================================================

-- 1. 테이블 리네이밍
ALTER TABLE health_memo_dtl RENAME TO memo_dtl;

-- 2. 신규 컬럼 추가 (V10 sync 컬럼은 이미 존재하므로 content / logged_at 만 추가)
ALTER TABLE memo_dtl ADD COLUMN content   TEXT;
ALTER TABLE memo_dtl ADD COLUMN logged_at TIMESTAMPTZ;

-- 3. 데이터 이전: symptom + treatment + memo → content, recorded_at → logged_at
UPDATE memo_dtl
SET content = TRIM(CONCAT_WS(E'\n',
                  NULLIF(TRIM(COALESCE(symptom,   '')), ''),
                  NULLIF(TRIM(COALESCE(treatment,  '')), ''),
                  NULLIF(TRIM(COALESCE(memo,       '')), ''))),
    logged_at = recorded_at;

-- content가 NULL인 경우 빈 문자열로 처리
UPDATE memo_dtl SET content = '' WHERE content IS NULL;

-- 4. NOT NULL 제약
ALTER TABLE memo_dtl ALTER COLUMN content   SET NOT NULL;
ALTER TABLE memo_dtl ALTER COLUMN logged_at SET NOT NULL;

-- 5. 구 컬럼 제거
ALTER TABLE memo_dtl DROP COLUMN IF EXISTS symptom;
ALTER TABLE memo_dtl DROP COLUMN IF EXISTS treatment;
ALTER TABLE memo_dtl DROP COLUMN IF EXISTS memo;
ALTER TABLE memo_dtl DROP COLUMN IF EXISTS recorded_at;

-- 6. 인덱스 교체
DROP INDEX IF EXISTS idx_health_memo_dtl_pet_time;
CREATE INDEX idx_memo_dtl_pet_time ON memo_dtl (pet_id, logged_at DESC) WHERE deleted_at IS NULL;

-- 7. UNIQUE 제약 이름 변경 (V10에서 uk_health_memo_dtl_sync 로 생성됨)
ALTER TABLE memo_dtl RENAME CONSTRAINT uk_health_memo_dtl_sync TO uk_memo_dtl_sync;

-- 8. 기존 트리거 교체 (health_memo_dtl → memo_dtl)
DROP TRIGGER IF EXISTS trg_health_memo_dtl_sync_version ON memo_dtl;
CREATE TRIGGER trg_memo_dtl_sync_version
    BEFORE UPDATE ON memo_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

COMMENT ON TABLE memo_dtl IS '메모 기록 (health_memo_dtl 리네이밍, 태그 시스템 도입)';
