-- =============================================================================
-- V6: 개체 사진 (pet_photo_dtl)
-- V3에서 profile_photo_id 컬럼 추가만 했음 — 여기서 FK 제약 추가
-- =============================================================================

CREATE TABLE pet_photo_dtl (
    id        BIGSERIAL    PRIMARY KEY,
    pet_id    BIGINT       NOT NULL,
    s3_key    VARCHAR(255) NOT NULL,
    file_size INTEGER      NULL,
    mime_type VARCHAR(50)  NULL,
    width     INTEGER      NULL,
    height    INTEGER      NULL,
    taken_at  TIMESTAMPTZ  NULL,
    caption   TEXT         NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_pet_photo_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE
);

CREATE INDEX idx_pet_photo_dtl_pet_time ON pet_photo_dtl(pet_id, taken_at DESC);

-- V3에서 미뤄뒀던 profile_photo_id FK 추가
ALTER TABLE pet_mst ADD CONSTRAINT fk_pet_mst_profile_photo
    FOREIGN KEY (profile_photo_id) REFERENCES pet_photo_dtl(id) ON DELETE SET NULL;

COMMENT ON TABLE  pet_photo_dtl        IS '개체 사진';
COMMENT ON COLUMN pet_photo_dtl.s3_key IS 'S3 객체 키 (LocalStack 개발 시 동일 구조)';
