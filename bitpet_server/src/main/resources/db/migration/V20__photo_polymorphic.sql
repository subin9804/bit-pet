-- =============================================================================
-- V20: photo_dtl 폴리모픽 통합 테이블 신규
--      pet_photo_dtl 데이터 이관 (ID 보존) + 구 테이블 DROP
-- =============================================================================

-- 1. photo_dtl 신규 생성
CREATE TABLE photo_dtl (
    id            BIGSERIAL    PRIMARY KEY,
    entity_type   VARCHAR(20)  NOT NULL,
    entity_id     BIGINT       NOT NULL,
    s3_key        VARCHAR(255) NOT NULL,
    file_size     INTEGER      NULL,
    mime_type     VARCHAR(50)  NULL,
    width         INTEGER      NULL,
    height        INTEGER      NULL,
    display_order INTEGER      NOT NULL DEFAULT 0,
    taken_at      TIMESTAMPTZ  NULL,
    caption       TEXT         NULL,
    deleted_at    TIMESTAMPTZ  NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_photo_entity_type CHECK (entity_type IN ('PET','MEMO','MATING','LAYING'))
);

CREATE INDEX idx_photo_entity ON photo_dtl (entity_type, entity_id, display_order);
CREATE INDEX idx_photo_entity_time ON photo_dtl (entity_type, entity_id, taken_at DESC)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_photo_pet    ON photo_dtl (entity_id, taken_at DESC)
    WHERE entity_type = 'PET'    AND deleted_at IS NULL;
CREATE INDEX idx_photo_memo   ON photo_dtl (entity_id, taken_at DESC)
    WHERE entity_type = 'MEMO'   AND deleted_at IS NULL;
CREATE INDEX idx_photo_mating ON photo_dtl (entity_id, taken_at DESC)
    WHERE entity_type = 'MATING' AND deleted_at IS NULL;
CREATE INDEX idx_photo_laying ON photo_dtl (entity_id, taken_at DESC)
    WHERE entity_type = 'LAYING' AND deleted_at IS NULL;

-- 2. pet_photo_dtl 데이터 이관 (ID 보존 — OVERRIDING SYSTEM VALUE)
INSERT INTO photo_dtl (id, entity_type, entity_id, s3_key, file_size, mime_type,
                       width, height, taken_at, caption, created_at, updated_at)
OVERRIDING SYSTEM VALUE
SELECT id, 'PET', pet_id, s3_key, file_size, mime_type,
       width, height, taken_at, caption, created_at, updated_at
FROM pet_photo_dtl;

-- SEQUENCE를 이전된 최대 ID 이후로 리셋
SELECT setval('photo_dtl_id_seq',
              COALESCE((SELECT MAX(id) FROM photo_dtl), 0) + 1,
              FALSE);

-- 3. pet_mst.profile_photo_id FK 교체 (ID 동일 → 데이터 UPDATE 불필요)
ALTER TABLE pet_mst DROP CONSTRAINT IF EXISTS fk_pet_mst_profile_photo;
ALTER TABLE pet_mst ADD CONSTRAINT fk_pet_mst_profile_photo
    FOREIGN KEY (profile_photo_id) REFERENCES photo_dtl(id) ON DELETE SET NULL;

-- 4. pet_photo_dtl FK 제거 후 테이블 DROP
ALTER TABLE pet_photo_dtl DROP CONSTRAINT IF EXISTS fk_pet_photo_dtl_pet;
DROP TABLE pet_photo_dtl;

COMMENT ON TABLE photo_dtl IS '폴리모픽 사진 테이블 (PET/MEMO/MATING/LAYING) — DB FK 없이 서비스 레이어에서 참조 무결성 관리';
COMMENT ON COLUMN photo_dtl.entity_type IS 'PET | MEMO | MATING | LAYING';
COMMENT ON COLUMN photo_dtl.entity_id   IS '대상 엔티티 PK (폴리모픽 → DB FK 미설정)';
