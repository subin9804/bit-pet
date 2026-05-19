-- =============================================================================
-- V2: pets 테이블
-- 참고: Pet 도메인의 _mst 네이밍 정렬은 추후 ERD 확정 후 별도 버전에서 처리.
--       이 버전은 기존 Pet 엔티티와 일치하는 스키마를 Flyway 통제 하에 둔다.
-- =============================================================================

CREATE TABLE pets (
    id            BIGSERIAL    PRIMARY KEY,
    serial_number VARCHAR(16)  NOT NULL,
    owner_id      BIGINT       NOT NULL,
    name          VARCHAR(50)  NOT NULL,
    species       VARCHAR(20)  NOT NULL,
    breed         VARCHAR(50)  NULL,
    birth_date    DATE         NULL,
    gender        VARCHAR(10)  NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_pets_serial_number UNIQUE (serial_number),
    CONSTRAINT fk_pets_owner
        FOREIGN KEY (owner_id) REFERENCES user_mst (id) ON DELETE CASCADE
);

CREATE INDEX idx_pets_owner_id ON pets (owner_id);
