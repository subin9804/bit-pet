-- =============================================================================
-- V9: 알림 이력 / 디바이스 토큰 / 알림 템플릿
-- v2.1 결정 #16: notification_log_dtl 1차 신규
-- =============================================================================

-- -----------------------------------------------------------------------------
-- notification_template_cd : 알림 템플릿 (선택적)
-- -----------------------------------------------------------------------------
CREATE TABLE notification_template_cd (
    id             BIGSERIAL    PRIMARY KEY,
    code           VARCHAR(50)  NOT NULL,
    title_template VARCHAR(255) NOT NULL,
    body_template  TEXT         NOT NULL,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_notification_template_cd_code UNIQUE (code)
);

COMMENT ON TABLE notification_template_cd IS '알림 템플릿 코드성 마스터';

-- -----------------------------------------------------------------------------
-- device_token_rls : FCM/APNs 디바이스 토큰
-- -----------------------------------------------------------------------------
CREATE TABLE device_token_rls (
    id           BIGSERIAL    PRIMARY KEY,
    user_id      BIGINT       NOT NULL,
    device_token VARCHAR(255) NOT NULL,
    platform     VARCHAR(10)  NOT NULL,
    device_info  VARCHAR(255) NULL,
    last_used_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_device_token_rls_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT uk_device_token_rls      UNIQUE (device_token),
    CONSTRAINT ck_device_token_platform CHECK (platform IN ('ANDROID', 'IOS'))
);

CREATE INDEX idx_device_token_rls_user_platform ON device_token_rls(user_id, platform);

COMMENT ON TABLE  device_token_rls          IS 'FCM/APNs 디바이스 토큰';
COMMENT ON COLUMN device_token_rls.platform IS 'ANDROID / IOS';

-- -----------------------------------------------------------------------------
-- notification_log_dtl : 알림 발송 이력
-- v2.1 결정 #22: 1차 신규
-- -----------------------------------------------------------------------------
CREATE TABLE notification_log_dtl (
    id            BIGSERIAL    PRIMARY KEY,
    user_id       BIGINT       NOT NULL,
    pet_id        BIGINT       NULL,
    routine_id    BIGINT       NULL,
    template_code VARCHAR(50)  NULL,
    title         VARCHAR(255) NOT NULL,
    body          TEXT         NULL,
    sent_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    status        VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    error_message TEXT         NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_notification_log_user    FOREIGN KEY (user_id)    REFERENCES user_mst(id),
    CONSTRAINT fk_notification_log_pet     FOREIGN KEY (pet_id)     REFERENCES pet_mst(id) ON DELETE SET NULL,
    CONSTRAINT fk_notification_log_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL,
    CONSTRAINT ck_notification_log_status  CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'READ'))
);

CREATE INDEX idx_notification_log_user_time ON notification_log_dtl(user_id, sent_at DESC);
CREATE INDEX idx_notification_log_status    ON notification_log_dtl(status, sent_at);

COMMENT ON TABLE  notification_log_dtl        IS '알림 발송 이력';
COMMENT ON COLUMN notification_log_dtl.status IS 'PENDING / SENT / FAILED / READ';
