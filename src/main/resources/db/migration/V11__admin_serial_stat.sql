-- =============================================================================
-- V11: 관리자 권한 분리 + 일련번호 풀 통계 테이블
-- v2.1 결정 #5: ADMIN 역할 제거 → admin_role_rls 분리
-- =============================================================================

-- -----------------------------------------------------------------------------
-- admin_role_rls : 관리자 권한 (user_type과 분리)
-- -----------------------------------------------------------------------------
CREATE TABLE admin_role_rls (
    id         BIGSERIAL    PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    role       VARCHAR(20)  NOT NULL,
    granted_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    granted_by BIGINT       NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_admin_role_user      FOREIGN KEY (user_id)    REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_admin_role_granter   FOREIGN KEY (granted_by) REFERENCES user_mst(id) ON DELETE SET NULL,
    CONSTRAINT uk_admin_role_rls       UNIQUE (user_id, role),
    CONSTRAINT ck_admin_role_rls_role  CHECK (role IN ('SUPER_ADMIN', 'MODERATOR'))
);

COMMENT ON TABLE  admin_role_rls        IS '관리자 권한 (user_type.GENERAL/BREEDER와 분리)';
COMMENT ON COLUMN admin_role_rls.role   IS 'SUPER_ADMIN / MODERATOR';

-- -----------------------------------------------------------------------------
-- serial_pool_stat_mst : 일련번호 풀 통계 (운영 모니터링)
-- -----------------------------------------------------------------------------
CREATE TABLE serial_pool_stat_mst (
    id             BIGSERIAL      PRIMARY KEY,
    serial_length  INTEGER        NOT NULL,
    total_capacity BIGINT         NOT NULL,
    used_count     BIGINT         NOT NULL DEFAULT 0,
    usage_rate     DECIMAL(5,4)   NOT NULL DEFAULT 0,
    is_current     BOOLEAN        NOT NULL DEFAULT false,
    expanded_at    TIMESTAMPTZ    NULL,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_serial_pool_stat_length UNIQUE (serial_length)
);

INSERT INTO serial_pool_stat_mst (serial_length, total_capacity, is_current) VALUES
    (6, 1073741824, true),   -- 32^6
    (7, 34359738368, false), -- 32^7
    (8, 1099511627776, false); -- 32^8

COMMENT ON TABLE  serial_pool_stat_mst             IS '일련번호 풀 사용량 통계 (Scheduler 일 1회 갱신)';
COMMENT ON COLUMN serial_pool_stat_mst.is_current  IS '현재 발급에 사용 중인 길이';
COMMENT ON COLUMN serial_pool_stat_mst.expanded_at IS '80% 도달로 확장된 시각';

-- user_mst user_type 기본값 comment 업데이트
COMMENT ON COLUMN user_mst.user_type IS 'GENERAL / BREEDER (ADMIN은 admin_role_rls로 분리)';
