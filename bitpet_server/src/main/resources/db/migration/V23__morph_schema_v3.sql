-- =============================================================================
-- V23: morph_cd v3.1/v3.2 스키마 업데이트 + pet_morph_rls 신설 + pet_mst 구조 정리
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. morph_cd 컬럼 확장 (v3.1 alias_list, v3.2 has_health_concern)
-- ─────────────────────────────────────────────────────────────────────────────

-- name_ko / name_en 길이 확장 (50 → 100)
ALTER TABLE morph_cd
    ALTER COLUMN name_ko TYPE VARCHAR(100),
    ALTER COLUMN name_en TYPE VARCHAR(100);

-- v3.1: alias_list — autocomplete 검색용 별명 (쉼표 구분)
ALTER TABLE morph_cd
    ADD COLUMN IF NOT EXISTS alias_list VARCHAR(300) NULL;

-- v3.2: has_health_concern — 유전 결함 동반 모프 표시
ALTER TABLE morph_cd
    ADD COLUMN IF NOT EXISTS has_health_concern BOOLEAN NOT NULL DEFAULT FALSE;

-- UNIQUE 제약 (같은 종 내 한글명 중복 방지)
ALTER TABLE morph_cd
    ADD CONSTRAINT uq_morph_cd_species_name_ko UNIQUE (species_id, name_ko);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. morph_cd 인덱스 추가
-- ─────────────────────────────────────────────────────────────────────────────

-- 종별 모프 선택 모달용 (species_id + is_active + display_order)
CREATE INDEX idx_morph_cd_species_order
    ON morph_cd (species_id, is_active, display_order);

-- autocomplete: 한국어 명칭 trigram
CREATE INDEX idx_morph_cd_name_ko_trgm
    ON morph_cd USING gin (name_ko gin_trgm_ops);

-- autocomplete: alias_list trigram (alias_list가 있는 행만)
CREATE INDEX idx_morph_cd_alias_trgm
    ON morph_cd USING gin (alias_list gin_trgm_ops)
    WHERE alias_list IS NOT NULL;

-- v3.2: 건강 우려 모프 부분 인덱스
CREATE INDEX idx_morph_cd_health_concern
    ON morph_cd (species_id, display_order)
    WHERE has_health_concern = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. pet_morph_rls 신설 (개체-모프 N:N, v3.1)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE pet_morph_rls (
    pet_id              BIGINT       NOT NULL,
    morph_id            BIGINT       NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    sync_version        BIGINT       NOT NULL DEFAULT 1,
    client_id           VARCHAR(64)  NULL,
    client_change_id    UUID         NULL,

    CONSTRAINT pk_pet_morph_rls             PRIMARY KEY (pet_id, morph_id),
    CONSTRAINT fk_pet_morph_rls_pet         FOREIGN KEY (pet_id)   REFERENCES pet_mst(id)   ON DELETE CASCADE,
    CONSTRAINT fk_pet_morph_rls_morph       FOREIGN KEY (morph_id) REFERENCES morph_cd(id)  ON DELETE RESTRICT,
    CONSTRAINT uq_pet_morph_rls_client      UNIQUE (client_id, client_change_id)
);

-- 모프별 개체 역조회용 (morph_id → pet_id)
CREATE INDEX idx_pet_morph_rls_morph_id ON pet_morph_rls (morph_id, pet_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. pet_mst.morph_id → pet_morph_rls 데이터 이관 후 컬럼 제거 (v3.1)
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO pet_morph_rls (pet_id, morph_id, created_at)
SELECT id, morph_id, COALESCE(updated_at, NOW())
  FROM pet_mst
 WHERE morph_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE pet_mst DROP CONSTRAINT IF EXISTS fk_pet_mst_morph;
ALTER TABLE pet_mst DROP COLUMN IF EXISTS morph_id;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. pet_mst.environment_memo → description 병합 후 컬럼 제거 (v3.1)
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE pet_mst
   SET description = CONCAT_WS(E'\n\n',
                                NULLIF(TRIM(description), ''),
                                NULLIF(TRIM(environment_memo), ''))
 WHERE environment_memo IS NOT NULL
   AND TRIM(environment_memo) != '';

ALTER TABLE pet_mst DROP COLUMN IF EXISTS environment_memo;
