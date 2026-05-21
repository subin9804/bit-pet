-- =============================================================================
-- V13: 루틴 도메인 재설계 (v3.1/v3.2)
-- - routine_mst: pet_id → user_id, alarm_time/is_alarm_enabled 통합
-- - alarm_mst 제거
-- - routine_pet_rls 신규 (루틴-개체 다대다)
-- - routine_log_dtl 신규 (루틴 실행 기록, status COMPLETED/REFUSED)
-- - feeding_dtl: routine_id FK + feed_response 추가
-- - notification_log_dtl: pet_count 추가
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. alarm_mst 제거 (routine_mst.alarm_time/is_alarm_enabled으로 통합)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS alarm_mst CASCADE;

-- -----------------------------------------------------------------------------
-- 2. routine_mst 재설계 (pet_id → user_id, 알람 컬럼 통합)
-- -----------------------------------------------------------------------------
ALTER TABLE routine_mst
    DROP CONSTRAINT IF EXISTS fk_routine_mst_pet,
    DROP COLUMN IF EXISTS pet_id;

ALTER TABLE routine_mst
    ADD COLUMN user_id          BIGINT       NOT NULL DEFAULT 0,
    ADD COLUMN alarm_time       TIME         NULL,
    ADD COLUMN is_alarm_enabled BOOLEAN      NOT NULL DEFAULT false;

-- 기존 타입 체크 업데이트 (WEIGHT 추가)
ALTER TABLE routine_mst DROP CONSTRAINT IF EXISTS ck_routine_mst_type;
ALTER TABLE routine_mst
    ADD CONSTRAINT ck_routine_mst_type CHECK (routine_type IN ('FEEDING', 'CLEANING', 'WEIGHT', 'CUSTOM'));

-- user_id 기본값 제거 후 FK 추가
ALTER TABLE routine_mst ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE routine_mst
    ADD CONSTRAINT fk_routine_mst_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- 인덱스 재생성
DROP INDEX IF EXISTS idx_routine_mst_pet_active;
CREATE INDEX idx_routine_mst_user_active ON routine_mst(user_id, is_active);

DROP INDEX IF EXISTS idx_routine_mst_next_due;
CREATE INDEX idx_routine_mst_next_due
    ON routine_mst(next_due_at)
    WHERE is_active = true AND is_alarm_enabled = true;

COMMENT ON COLUMN routine_mst.user_id          IS '루틴 소유자 (v2.4: pet_id 에서 변경)';
COMMENT ON COLUMN routine_mst.alarm_time        IS '알림 시각 (v2.1: alarm_mst 통합)';
COMMENT ON COLUMN routine_mst.is_alarm_enabled  IS '알림 켜기/끄기';

-- -----------------------------------------------------------------------------
-- 3. routine_pet_rls : 루틴-개체 다대다 (v2.4 신규)
-- -----------------------------------------------------------------------------
CREATE TABLE routine_pet_rls (
    id               BIGSERIAL    PRIMARY KEY,
    routine_id       BIGINT       NOT NULL,
    pet_id           BIGINT       NOT NULL,
    sync_version     BIGINT       NOT NULL DEFAULT 1,
    client_id        VARCHAR(64)  NULL,
    client_change_id UUID         NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_routine_pet_rls_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_routine_pet_rls_pet     FOREIGN KEY (pet_id)     REFERENCES pet_mst(id)     ON DELETE CASCADE,
    CONSTRAINT uq_routine_pet_rls         UNIQUE (routine_id, pet_id)
);

CREATE INDEX idx_routine_pet_rls_routine ON routine_pet_rls(routine_id);
CREATE INDEX idx_routine_pet_rls_pet     ON routine_pet_rls(pet_id);

COMMENT ON TABLE routine_pet_rls IS '루틴-개체 다대다 연결 (v2.4 신규)';

-- -----------------------------------------------------------------------------
-- 4. routine_log_dtl : 루틴 실행 기록 (v2.5: status 컬럼 포함)
-- -----------------------------------------------------------------------------
CREATE TABLE routine_log_dtl (
    id          BIGSERIAL    PRIMARY KEY,
    routine_id  BIGINT       NOT NULL,
    pet_id      BIGINT       NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'COMPLETED',
    executed_at TIMESTAMPTZ  NOT NULL,
    extra_data  JSONB        NULL,
    memo        TEXT         NULL,
    deleted_at  TIMESTAMPTZ  NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_routine_log_dtl_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_routine_log_dtl_pet     FOREIGN KEY (pet_id)     REFERENCES pet_mst(id)     ON DELETE CASCADE,
    CONSTRAINT ck_routine_log_dtl_status  CHECK (status IN ('COMPLETED', 'REFUSED'))
);

CREATE INDEX idx_routine_log_dtl_routine_time
    ON routine_log_dtl(routine_id, executed_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_routine_log_dtl_pet_time
    ON routine_log_dtl(pet_id, executed_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_routine_log_dtl_progress
    ON routine_log_dtl(routine_id, pet_id, executed_at DESC)
    WHERE deleted_at IS NULL AND status = 'COMPLETED';

COMMENT ON TABLE  routine_log_dtl        IS '루틴 실행 기록 (v2.3+). FEEDING은 feeding_dtl에 기록.';
COMMENT ON COLUMN routine_log_dtl.status IS 'COMPLETED: 완료, REFUSED: 명시적 미수행+메모';
COMMENT ON COLUMN routine_log_dtl.extra_data IS 'CLEANING: {"cleaning_type":"FULL"}, WEIGHT: {"weight_g":76.5}';

-- -----------------------------------------------------------------------------
-- 5. feeding_dtl : routine_id FK + feed_response 추가
-- -----------------------------------------------------------------------------
ALTER TABLE feeding_dtl
    ADD COLUMN routine_id     BIGINT       NULL,
    ADD COLUMN feed_response  VARCHAR(20)  NULL;

ALTER TABLE feeding_dtl
    ADD CONSTRAINT fk_feeding_dtl_routine   FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL,
    ADD CONSTRAINT ck_feeding_dtl_response  CHECK (feed_response IN ('COMPLETE', 'PARTIAL', 'REFUSED') OR feed_response IS NULL);

CREATE INDEX idx_feeding_dtl_routine ON feeding_dtl(routine_id, fed_at DESC) WHERE deleted_at IS NULL;

COMMENT ON COLUMN feeding_dtl.routine_id    IS '연결된 루틴 (없으면 수동 기록)';
COMMENT ON COLUMN feeding_dtl.feed_response IS 'COMPLETE / PARTIAL / REFUSED';

-- -----------------------------------------------------------------------------
-- 6. notification_log_dtl : pet_count 추가 (v2.4)
-- -----------------------------------------------------------------------------
ALTER TABLE notification_log_dtl
    ADD COLUMN pet_count INTEGER NULL;

COMMENT ON COLUMN notification_log_dtl.pet_count  IS '알림 발송 시점 연결 개체 수 (분석용)';
COMMENT ON COLUMN notification_log_dtl.pet_id     IS 'v2.4: 대표 개체 ID (다개체 알림 시 pet_id ASC LIMIT 1)';
