-- =============================================================================
-- V4: 기록 도메인 (weight_dtl, feeding_dtl, cleaning_dtl, health_memo_dtl)
-- 모든 기록 테이블: pet_id FK + 시계열 인덱스 + deleted_at tombstone
-- =============================================================================

-- -----------------------------------------------------------------------------
-- weight_dtl : 체중 기록
-- -----------------------------------------------------------------------------
CREATE TABLE weight_dtl (
    id          BIGSERIAL      PRIMARY KEY,
    pet_id      BIGINT         NOT NULL,
    weight_g    DECIMAL(8,2)   NOT NULL,
    measured_at TIMESTAMPTZ    NOT NULL,
    source      VARCHAR(20)    NOT NULL DEFAULT 'MANUAL',
    memo        TEXT           NULL,
    deleted_at  TIMESTAMPTZ    NULL,
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_weight_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE,
    CONSTRAINT ck_weight_dtl_source CHECK (source IN ('MANUAL', 'BLUETOOTH'))
);

CREATE INDEX idx_weight_dtl_pet_time ON weight_dtl(pet_id, measured_at DESC) WHERE deleted_at IS NULL;

COMMENT ON TABLE weight_dtl IS '체중 기록';
COMMENT ON COLUMN weight_dtl.source IS 'MANUAL / BLUETOOTH (2차)';

-- -----------------------------------------------------------------------------
-- feeding_dtl : 급여 기록
-- -----------------------------------------------------------------------------
CREATE TABLE feeding_dtl (
    id        BIGSERIAL    PRIMARY KEY,
    pet_id    BIGINT       NOT NULL,
    food_type VARCHAR(50)  NOT NULL,
    amount    DECIMAL(6,2) NULL,
    unit      VARCHAR(10)  NULL,
    fed_at    TIMESTAMPTZ  NOT NULL,
    memo      TEXT         NULL,
    deleted_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_feeding_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE
);

CREATE INDEX idx_feeding_dtl_pet_time ON feeding_dtl(pet_id, fed_at DESC) WHERE deleted_at IS NULL;

COMMENT ON TABLE feeding_dtl IS '급여 기록';

-- -----------------------------------------------------------------------------
-- cleaning_dtl : 청소 기록
-- -----------------------------------------------------------------------------
CREATE TABLE cleaning_dtl (
    id            BIGSERIAL   PRIMARY KEY,
    pet_id        BIGINT      NOT NULL,
    cleaning_type VARCHAR(20) NOT NULL,
    cleaned_at    TIMESTAMPTZ NOT NULL,
    memo          TEXT        NULL,
    deleted_at    TIMESTAMPTZ NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cleaning_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE,
    CONSTRAINT ck_cleaning_dtl_type CHECK (cleaning_type IN ('FULL', 'PARTIAL', 'WATER_CHANGE'))
);

CREATE INDEX idx_cleaning_dtl_pet_time ON cleaning_dtl(pet_id, cleaned_at DESC) WHERE deleted_at IS NULL;

COMMENT ON TABLE cleaning_dtl IS '청소 기록';

-- -----------------------------------------------------------------------------
-- health_memo_dtl : 건강 메모
-- -----------------------------------------------------------------------------
CREATE TABLE health_memo_dtl (
    id          BIGSERIAL   PRIMARY KEY,
    pet_id      BIGINT      NOT NULL,
    symptom     VARCHAR(100) NULL,
    treatment   TEXT        NULL,
    memo        TEXT        NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    deleted_at  TIMESTAMPTZ NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_health_memo_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE
);

CREATE INDEX idx_health_memo_dtl_pet_time ON health_memo_dtl(pet_id, recorded_at DESC) WHERE deleted_at IS NULL;

COMMENT ON TABLE health_memo_dtl IS '건강 메모';
