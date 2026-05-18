-- =============================================================================
-- V7: 개체 관계 도메인 (pet_relation_rls, mating_rls)
-- v2.1 결정 #19: mating_rls 등록 후 pet_relation_rls는 수동 등록
-- =============================================================================

-- -----------------------------------------------------------------------------
-- pet_relation_rls : 부모-자식 관계
-- -----------------------------------------------------------------------------
CREATE TABLE pet_relation_rls (
    id             BIGSERIAL   PRIMARY KEY,
    parent_pet_id  BIGINT      NOT NULL,
    child_pet_id   BIGINT      NOT NULL,
    relation_type  VARCHAR(10) NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_pet_relation_parent FOREIGN KEY (parent_pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_pet_relation_child  FOREIGN KEY (child_pet_id)  REFERENCES pet_mst(id) ON DELETE CASCADE,
    CONSTRAINT uk_pet_relation        UNIQUE (parent_pet_id, child_pet_id, relation_type),
    CONSTRAINT ck_pet_relation_type   CHECK (relation_type IN ('FATHER', 'MOTHER'))
);

CREATE INDEX idx_pet_relation_child ON pet_relation_rls(child_pet_id);

COMMENT ON TABLE  pet_relation_rls              IS '부모-자식 관계';
COMMENT ON COLUMN pet_relation_rls.relation_type IS 'FATHER / MOTHER';

-- -----------------------------------------------------------------------------
-- mating_rls : 메이팅 기록
-- v2.1 결정 #19: mating 등록 후 pet_relation_rls는 수동으로 등록
-- -----------------------------------------------------------------------------
CREATE TABLE mating_rls (
    id             BIGSERIAL PRIMARY KEY,
    male_pet_id    BIGINT    NOT NULL,
    female_pet_id  BIGINT    NOT NULL,
    mating_date    DATE      NOT NULL,
    memo           TEXT      NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mating_rls_male   FOREIGN KEY (male_pet_id)   REFERENCES pet_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_mating_rls_female FOREIGN KEY (female_pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE
);

CREATE INDEX idx_mating_rls_male        ON mating_rls(male_pet_id);
CREATE INDEX idx_mating_rls_female      ON mating_rls(female_pet_id);
CREATE INDEX idx_mating_rls_date_desc   ON mating_rls(mating_date DESC);

COMMENT ON TABLE mating_rls IS '메이팅 기록 (부모-자식 연결은 pet_relation_rls에 수동 등록)';
