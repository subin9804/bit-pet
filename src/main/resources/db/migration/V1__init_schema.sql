-- =============================================================================
-- V1: 초기 스키마 (user_mst, user_oauth_rls)
-- 명명 규칙: 핵심=_mst, 상세/이력=_dtl, 관계=_rls, 코드성=_cd
-- 공통 컬럼: id BIGSERIAL PK, created_at/updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- =============================================================================

-- -----------------------------------------------------------------------------
-- user_mst : 사용자 마스터
-- -----------------------------------------------------------------------------
CREATE TABLE user_mst (
    id                BIGSERIAL    PRIMARY KEY,
    email             VARCHAR(255) NOT NULL,
    password_hash     VARCHAR(255) NOT NULL,
    name              VARCHAR(50)  NOT NULL,
    profile_image_url TEXT         NULL,
    user_type         VARCHAR(20)  NOT NULL DEFAULT 'GENERAL',
    last_login_at     TIMESTAMPTZ  NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ  NULL,
    CONSTRAINT uk_user_mst_email UNIQUE (email)
);

CREATE INDEX idx_user_mst_email ON user_mst (email);

COMMENT ON TABLE  user_mst                     IS '사용자 마스터';
COMMENT ON COLUMN user_mst.email               IS '로그인 이메일 (UNIQUE)';
COMMENT ON COLUMN user_mst.password_hash       IS 'bcrypt 해시';
COMMENT ON COLUMN user_mst.name                IS '표시 이름';
COMMENT ON COLUMN user_mst.user_type           IS 'GENERAL / ADMIN';
COMMENT ON COLUMN user_mst.last_login_at       IS '최근 로그인 일시';
COMMENT ON COLUMN user_mst.deleted_at          IS 'Soft Delete 일시 (NULL이면 활성)';

-- -----------------------------------------------------------------------------
-- user_oauth_rls : 사용자 ↔ OAuth 공급자 연결 (1:N)
-- -----------------------------------------------------------------------------
CREATE TABLE user_oauth_rls (
    id                BIGSERIAL    PRIMARY KEY,
    user_id           BIGINT       NOT NULL,
    provider          VARCHAR(20)  NOT NULL,
    provider_user_id  VARCHAR(255) NOT NULL,
    provider_email    VARCHAR(255) NULL,
    access_token      TEXT         NULL,
    refresh_token     TEXT         NULL,
    token_expires_at  TIMESTAMPTZ  NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_oauth_rls_user
        FOREIGN KEY (user_id) REFERENCES user_mst (id) ON DELETE CASCADE,
    CONSTRAINT uk_user_oauth_rls_provider_user
        UNIQUE (provider, provider_user_id),
    CONSTRAINT ck_user_oauth_rls_provider
        CHECK (provider IN ('GOOGLE', 'KAKAO', 'NAVER'))
);

CREATE INDEX idx_user_oauth_rls_user_id          ON user_oauth_rls (user_id);
CREATE INDEX idx_user_oauth_rls_provider_pid     ON user_oauth_rls (provider, provider_user_id);

COMMENT ON TABLE  user_oauth_rls                  IS '사용자-OAuth 공급자 연결';
COMMENT ON COLUMN user_oauth_rls.provider         IS 'GOOGLE / KAKAO / NAVER';
COMMENT ON COLUMN user_oauth_rls.provider_user_id IS '공급자측 식별자 (sub 등)';
