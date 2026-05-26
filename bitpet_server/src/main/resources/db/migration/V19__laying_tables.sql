-- =============================================================================
-- V19: laying_dtl (산란·클러치) + laying_hatch_dtl (해칭) 신규
-- =============================================================================

-- -----------------------------------------------------------------------------
-- laying_dtl : 산란(클러치) 기록
-- -----------------------------------------------------------------------------
CREATE TABLE laying_dtl (
    id                   BIGSERIAL    PRIMARY KEY,
    pet_id               BIGINT       NOT NULL,
    mating_id            BIGINT       NULL,
    laid_at              TIMESTAMPTZ  NOT NULL,
    egg_count_total      INTEGER      NOT NULL,
    egg_count_fertile    INTEGER      NULL,
    incubation_temp      DECIMAL(4,1) NULL,
    incubation_humidity  DECIMAL(4,1) NULL,
    memo                 TEXT         NULL,
    deleted_at           TIMESTAMPTZ  NULL,
    sync_version         BIGINT       NOT NULL DEFAULT 1,
    client_id            VARCHAR(64)  NULL,
    client_change_id     UUID         NULL,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_laying_dtl_pet    FOREIGN KEY (pet_id)    REFERENCES pet_mst(id)    ON DELETE CASCADE,
    CONSTRAINT fk_laying_dtl_mating FOREIGN KEY (mating_id) REFERENCES mating_dtl(id) ON DELETE SET NULL,
    CONSTRAINT chk_laying_egg_total_positive   CHECK (egg_count_total > 0),
    CONSTRAINT chk_laying_fertile_lte_total    CHECK (egg_count_fertile IS NULL OR egg_count_fertile <= egg_count_total),
    CONSTRAINT chk_laying_fertile_non_negative CHECK (egg_count_fertile IS NULL OR egg_count_fertile >= 0),
    CONSTRAINT chk_laying_temp_range           CHECK (incubation_temp IS NULL OR (incubation_temp BETWEEN 0 AND 50)),
    CONSTRAINT chk_laying_humidity_range       CHECK (incubation_humidity IS NULL OR (incubation_humidity BETWEEN 0 AND 100))
);

CREATE INDEX idx_laying_dtl_pet_time ON laying_dtl (pet_id, laid_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_laying_dtl_mating   ON laying_dtl (mating_id) WHERE mating_id IS NOT NULL;
ALTER TABLE laying_dtl ADD CONSTRAINT uk_laying_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER trg_laying_dtl_sync_version
    BEFORE UPDATE ON laying_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- -----------------------------------------------------------------------------
-- laying_hatch_dtl : 클러치별 해칭 추적
-- -----------------------------------------------------------------------------
CREATE TABLE laying_hatch_dtl (
    id               BIGSERIAL   PRIMARY KEY,
    laying_id        BIGINT      NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    hatched_at       TIMESTAMPTZ NULL,
    hatched_pet_id   BIGINT      NULL,
    memo             TEXT        NULL,
    deleted_at       TIMESTAMPTZ NULL,
    sync_version     BIGINT      NOT NULL DEFAULT 1,
    client_id        VARCHAR(64) NULL,
    client_change_id UUID        NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_hatch_laying  FOREIGN KEY (laying_id)      REFERENCES laying_dtl(id) ON DELETE CASCADE,
    CONSTRAINT fk_hatch_pet     FOREIGN KEY (hatched_pet_id) REFERENCES pet_mst(id)    ON DELETE SET NULL,
    CONSTRAINT chk_hatch_status CHECK (status IN ('PENDING','HATCHED','FAILED','SLUG')),
    CONSTRAINT chk_hatch_hatched_at CHECK (status <> 'HATCHED' OR hatched_at IS NOT NULL)
);

CREATE INDEX idx_hatch_laying_status ON laying_hatch_dtl (laying_id, status);
CREATE INDEX idx_hatch_hatched_pet   ON laying_hatch_dtl (hatched_pet_id) WHERE hatched_pet_id IS NOT NULL;
ALTER TABLE laying_hatch_dtl ADD CONSTRAINT uk_hatch_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER trg_laying_hatch_dtl_sync_version
    BEFORE UPDATE ON laying_hatch_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

COMMENT ON TABLE laying_dtl              IS '산란(클러치) 기록 — 해칭은 laying_hatch_dtl 1:N';
COMMENT ON TABLE laying_hatch_dtl        IS '클러치별 해칭 추적 (PENDING/HATCHED/FAILED/SLUG)';
COMMENT ON COLUMN laying_dtl.mating_id   IS '연관 메이팅 (선택) — mating 삭제 시 NULL SET';
COMMENT ON COLUMN laying_hatch_dtl.hatched_pet_id IS '해칭→개체 등록 시 pet_mst.id 연결, 자동 pet_relation_rls 생성';
