-- =============================================================================
-- V16: memo_tag_cd — 메모 태그 코드 마스터 신규
-- =============================================================================

CREATE TABLE memo_tag_cd (
    id             BIGSERIAL    PRIMARY KEY,
    code           VARCHAR(30)  NOT NULL,
    label_ko       VARCHAR(50)  NOT NULL,
    label_en       VARCHAR(50)  NULL,
    color_code     VARCHAR(7)   NULL,
    display_order  INTEGER      NOT NULL DEFAULT 0,
    is_system      BOOLEAN      NOT NULL DEFAULT TRUE,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_memo_tag_cd_code UNIQUE (code)
);

CREATE INDEX idx_memo_tag_cd_active_order ON memo_tag_cd (is_active, display_order);

-- 시스템 기본 태그 시딩
INSERT INTO memo_tag_cd (code, label_ko, label_en, color_code, display_order, is_system, is_active) VALUES
    ('VET',      '병원', 'Hospital', '#E74C3C',  1, TRUE, TRUE),
    ('SHED',     '탈피', 'Shedding', '#3498DB',  2, TRUE, TRUE),
    ('BEHAVIOR', '행동', 'Behavior', '#9B59B6',  3, TRUE, TRUE),
    ('ETC',      '기타', 'Etc',      '#95A5A6', 99, TRUE, TRUE);

COMMENT ON TABLE  memo_tag_cd           IS '메모 태그 코드 마스터 (enum 대신 코드 테이블, 사용자 정의 태그 확장 여지)';
COMMENT ON COLUMN memo_tag_cd.is_system IS 'TRUE이면 시스템 기본 태그 (삭제 불가)';
