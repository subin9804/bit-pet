-- =============================================================================
-- V5: 루틴 / 알람 도메인
-- v2.1 결정 #18: routine_mst UNIQUE(pet_id, routine_type) 제거 → 다중 주기 허용
-- =============================================================================

-- -----------------------------------------------------------------------------
-- routine_mst : 루틴 (다중 주기 허용)
-- -----------------------------------------------------------------------------
CREATE TABLE routine_mst (
    id               BIGSERIAL   PRIMARY KEY,
    pet_id           BIGINT      NOT NULL,
    routine_type     VARCHAR(20) NOT NULL,
    title            VARCHAR(100) NOT NULL,
    cycle_days       INTEGER     NOT NULL,
    last_executed_at TIMESTAMPTZ NULL,
    next_due_at      TIMESTAMPTZ NULL,
    is_active        BOOLEAN     NOT NULL DEFAULT true,
    memo             TEXT        NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_routine_mst_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE,
    CONSTRAINT ck_routine_mst_type  CHECK (routine_type IN ('FEEDING', 'CLEANING', 'CUSTOM')),
    CONSTRAINT ck_routine_mst_cycle CHECK (cycle_days > 0)
);

CREATE INDEX idx_routine_mst_pet_active ON routine_mst(pet_id, is_active);
CREATE INDEX idx_routine_mst_next_due   ON routine_mst(next_due_at) WHERE is_active = true;

COMMENT ON TABLE  routine_mst             IS '루틴 (UNIQUE 제약 없음 — 다중 주기 허용)';
COMMENT ON COLUMN routine_mst.cycle_days  IS '주기 (일 단위, 양수)';
COMMENT ON COLUMN routine_mst.next_due_at IS '다음 예정 시각 (스케줄러 파생)';

-- -----------------------------------------------------------------------------
-- alarm_mst : 알람 설정
-- -----------------------------------------------------------------------------
CREATE TABLE alarm_mst (
    id         BIGSERIAL PRIMARY KEY,
    routine_id BIGINT    NOT NULL,
    alarm_time TIME      NOT NULL,
    is_enabled BOOLEAN   NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_alarm_mst_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE CASCADE
);

CREATE INDEX idx_alarm_mst_routine ON alarm_mst(routine_id, is_enabled);

COMMENT ON TABLE alarm_mst IS '알람 설정 (루틴당 N개 가능)';
