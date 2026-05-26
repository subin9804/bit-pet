-- =============================================================================
-- V18: mating_rls → mating_dtl 리네이밍 + 기록 도메인 승격 + 컬럼 확장
-- mating_rls (pet 도메인 보조) → mating_dtl (record 도메인 1급 카테고리)
-- =============================================================================

-- 1. 테이블 리네이밍
ALTER TABLE mating_rls RENAME TO mating_dtl;

-- 2. FK nullable로 변경 (외부 개체 지원)
ALTER TABLE mating_dtl ALTER COLUMN male_pet_id   DROP NOT NULL;
ALTER TABLE mating_dtl ALTER COLUMN female_pet_id DROP NOT NULL;

-- 3. FK ON DELETE 변경: CASCADE → SET NULL
ALTER TABLE mating_dtl DROP CONSTRAINT fk_mating_rls_male;
ALTER TABLE mating_dtl DROP CONSTRAINT fk_mating_rls_female;
ALTER TABLE mating_dtl ADD CONSTRAINT fk_mating_dtl_male
    FOREIGN KEY (male_pet_id)   REFERENCES pet_mst(id) ON DELETE SET NULL;
ALTER TABLE mating_dtl ADD CONSTRAINT fk_mating_dtl_female
    FOREIGN KEY (female_pet_id) REFERENCES pet_mst(id) ON DELETE SET NULL;

-- 4. 신규 컬럼 추가
ALTER TABLE mating_dtl ADD COLUMN external_partner_text VARCHAR(255);
ALTER TABLE mating_dtl ADD COLUMN duration_minutes      INTEGER;
ALTER TABLE mating_dtl ADD COLUMN is_successful         BOOLEAN;
ALTER TABLE mating_dtl ADD COLUMN season_label          VARCHAR(20);
ALTER TABLE mating_dtl ADD COLUMN deleted_at            TIMESTAMPTZ;
ALTER TABLE mating_dtl ADD COLUMN sync_version          BIGINT NOT NULL DEFAULT 1;
ALTER TABLE mating_dtl ADD COLUMN client_id             VARCHAR(64);
ALTER TABLE mating_dtl ADD COLUMN client_change_id      UUID;

-- 5. mating_date(DATE) → tried_at(TIMESTAMPTZ)
ALTER TABLE mating_dtl ADD COLUMN tried_at TIMESTAMPTZ;
UPDATE mating_dtl SET tried_at = mating_date::TIMESTAMPTZ;
ALTER TABLE mating_dtl ALTER COLUMN tried_at SET NOT NULL;
ALTER TABLE mating_dtl DROP COLUMN mating_date;

-- 6. season_label 백필 (tried_at 기준 년도)
UPDATE mating_dtl
SET season_label = EXTRACT(YEAR FROM tried_at)::TEXT
WHERE season_label IS NULL;
ALTER TABLE mating_dtl ALTER COLUMN season_label SET NOT NULL;

-- 7. CHECK 제약: 최소 한 마리는 내부 개체
ALTER TABLE mating_dtl ADD CONSTRAINT chk_mating_at_least_one_pet
    CHECK (male_pet_id IS NOT NULL OR female_pet_id IS NOT NULL);

-- 8. 인덱스 교체
DROP INDEX IF EXISTS idx_mating_rls_male;
DROP INDEX IF EXISTS idx_mating_rls_female;
DROP INDEX IF EXISTS idx_mating_rls_date_desc;

CREATE INDEX idx_mating_dtl_male   ON mating_dtl (male_pet_id,   tried_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_mating_dtl_female ON mating_dtl (female_pet_id, tried_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_mating_dtl_season ON mating_dtl (season_label);
ALTER TABLE mating_dtl ADD CONSTRAINT uk_mating_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- 9. sync 트리거
CREATE TRIGGER trg_mating_dtl_sync_version
    BEFORE UPDATE ON mating_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

COMMENT ON TABLE  mating_dtl                     IS '메이팅 기록 (기록 도메인 1급 카테고리로 승격, mating_rls에서 이동)';
COMMENT ON COLUMN mating_dtl.is_successful       IS 'NULL=미확인, TRUE=성공, FALSE=실패 — 산란 확인 후 업데이트';
COMMENT ON COLUMN mating_dtl.external_partner_text IS '외부 개체 정보 자유 텍스트 (male/female 중 하나가 NULL일 때)';
