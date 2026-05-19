-- =============================================================================
-- V12: morph_cd 테이블 + pet_mst 컬럼 추가 (morph_id, description)
-- =============================================================================

CREATE TABLE morph_cd (
    id            BIGSERIAL    PRIMARY KEY,
    species_id    BIGINT       NOT NULL,
    name_ko       VARCHAR(50)  NOT NULL,
    name_en       VARCHAR(50)  NULL,
    display_order SMALLINT     NOT NULL DEFAULT 0,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_morph_cd_species FOREIGN KEY (species_id) REFERENCES species_cd(id)
);

CREATE INDEX idx_morph_cd_species ON morph_cd(species_id) WHERE is_active = TRUE;

COMMENT ON TABLE morph_cd IS '모프(색상변이) 코드 마스터';

ALTER TABLE pet_mst
    ADD COLUMN morph_id     BIGINT NULL,
    ADD COLUMN description  TEXT   NULL;

ALTER TABLE pet_mst
    ADD CONSTRAINT fk_pet_mst_morph FOREIGN KEY (morph_id) REFERENCES morph_cd(id);
