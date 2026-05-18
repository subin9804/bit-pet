-- =============================================================================
-- V3: pet 도메인 재구성 + 코드 마스터 신규
-- - email 부분 인덱스 업그레이드 (B2)
-- - species_cd 마스터 테이블 신규
-- - post_category_cd 마스터 테이블 + 4개 고정 카테고리 시드
-- - pets → pet_mst rename + 컬럼 재정렬
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B2: user_mst email UNIQUE → 부분 인덱스 (Soft Delete 대응)
-- -----------------------------------------------------------------------------
ALTER TABLE user_mst DROP CONSTRAINT uk_user_mst_email;
DROP INDEX IF EXISTS idx_user_mst_email;
CREATE UNIQUE INDEX idx_user_mst_email_active ON user_mst(email) WHERE deleted_at IS NULL;

-- -----------------------------------------------------------------------------
-- species_cd : 종 마스터 (PetSpecies enum 대체)
-- -----------------------------------------------------------------------------
CREATE TABLE species_cd (
    id              BIGSERIAL    PRIMARY KEY,
    code            VARCHAR(50)  NOT NULL,
    category        VARCHAR(20)  NOT NULL,
    subcategory     VARCHAR(20)  NULL,
    name_ko         VARCHAR(100) NOT NULL,
    name_en         VARCHAR(100) NULL,
    scientific_name VARCHAR(150) NULL,
    display_order   INTEGER      NOT NULL DEFAULT 0,
    is_active       BOOLEAN      NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_species_cd_code UNIQUE (code),
    CONSTRAINT ck_species_cd_category CHECK (category IN ('REPTILE', 'AMPHIBIAN'))
);

CREATE INDEX idx_species_cd_category ON species_cd(category, subcategory);
CREATE INDEX idx_species_cd_display_order ON species_cd(display_order);

COMMENT ON TABLE  species_cd               IS '종 마스터 (배포 없이 종 추가 가능)';
COMMENT ON COLUMN species_cd.code          IS 'LEOPARD_GECKO 등 시스템 코드';
COMMENT ON COLUMN species_cd.category     IS 'REPTILE / AMPHIBIAN';
COMMENT ON COLUMN species_cd.subcategory  IS 'LIZARD / GECKO / IGUANA / TURTLE / SNAKE / FROG 등';

-- -----------------------------------------------------------------------------
-- post_category_cd : 게시판 카테고리 (4개 고정)
-- -----------------------------------------------------------------------------
CREATE TABLE post_category_cd (
    id            BIGSERIAL   PRIMARY KEY,
    code          VARCHAR(20) NOT NULL,
    name_ko       VARCHAR(50) NOT NULL,
    description   TEXT        NULL,
    display_order INTEGER     NOT NULL DEFAULT 0,
    is_active     BOOLEAN     NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_post_category_cd_code UNIQUE (code)
);

INSERT INTO post_category_cd (code, name_ko, description, display_order) VALUES
    ('FREE',     '자유게시판', '일상·사진 공유',                               1),
    ('QNA',      'QnA',        '사육 관련 질문·답변',                         2),
    ('INFO',     '정보게시판', '종별 사육 정보·팁',                            3),
    ('ADOPTION', '분양게시판', '개체 분양 정보 공유 (결제·소유권 이전은 4차)', 4);

-- -----------------------------------------------------------------------------
-- pets → pet_mst 재구성
-- -----------------------------------------------------------------------------
ALTER TABLE pets RENAME TO pet_mst;

-- serial_number VARCHAR(16) → serial_no VARCHAR(8)
ALTER TABLE pet_mst RENAME COLUMN serial_number TO serial_no;
ALTER TABLE pet_mst ALTER COLUMN serial_no TYPE VARCHAR(8);

-- owner_id → user_id
ALTER TABLE pet_mst RENAME COLUMN owner_id TO user_id;

-- gender: NULL 값 → UNKNOWN 처리 후 NOT NULL
UPDATE pet_mst SET gender = 'UNKNOWN' WHERE gender IS NULL;
ALTER TABLE pet_mst ALTER COLUMN gender SET NOT NULL;
ALTER TABLE pet_mst ALTER COLUMN gender SET DEFAULT 'UNKNOWN';

-- 불필요 컬럼 제거 (v2.1 결정 #3, #21)
ALTER TABLE pet_mst DROP COLUMN IF EXISTS species;
ALTER TABLE pet_mst DROP COLUMN IF EXISTS breed;
ALTER TABLE pet_mst DROP COLUMN IF EXISTS birth_date;

-- 신규 컬럼 추가
ALTER TABLE pet_mst ADD COLUMN species_id        BIGINT      NULL;
ALTER TABLE pet_mst ADD COLUMN color_code        VARCHAR(7)  NULL;
ALTER TABLE pet_mst ADD COLUMN environment_memo  TEXT        NULL;
ALTER TABLE pet_mst ADD COLUMN breeding_date     DATE        NULL;
ALTER TABLE pet_mst ADD COLUMN hatching_date     DATE        NULL;
ALTER TABLE pet_mst ADD COLUMN adoption_date     DATE        NULL;
ALTER TABLE pet_mst ADD COLUMN profile_photo_id  BIGINT      NULL;
ALTER TABLE pet_mst ADD COLUMN deleted_at        TIMESTAMPTZ NULL;

-- FK 정리: 기존 fk_pets_owner 제거 후 신규 추가
ALTER TABLE pet_mst DROP CONSTRAINT fk_pets_owner;
ALTER TABLE pet_mst ADD CONSTRAINT fk_pet_mst_user
    FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;
ALTER TABLE pet_mst ADD CONSTRAINT fk_pet_mst_species
    FOREIGN KEY (species_id) REFERENCES species_cd(id);

-- 기존 제약·인덱스 정리
ALTER TABLE pet_mst DROP CONSTRAINT uk_pets_serial_number;
DROP INDEX IF EXISTS idx_pets_owner_id;

-- 신규 인덱스·제약
CREATE UNIQUE INDEX idx_pet_mst_serial_no ON pet_mst(serial_no) WHERE deleted_at IS NULL;
CREATE INDEX idx_pet_mst_user_id    ON pet_mst(user_id, deleted_at);
CREATE INDEX idx_pet_mst_species_id ON pet_mst(species_id);

ALTER TABLE pet_mst ADD CONSTRAINT ck_pet_mst_gender
    CHECK (gender IN ('MALE', 'FEMALE', 'UNKNOWN'));
ALTER TABLE pet_mst ADD CONSTRAINT ck_pet_mst_serial_no
    CHECK (LENGTH(serial_no) BETWEEN 6 AND 8);
ALTER TABLE pet_mst ADD CONSTRAINT ck_pet_mst_color_code
    CHECK (color_code IS NULL OR color_code ~ '^#[0-9A-Fa-f]{6}$');

COMMENT ON TABLE  pet_mst                  IS '개체 마스터 (v3 재구성)';
COMMENT ON COLUMN pet_mst.serial_no        IS '외부 노출용 일련번호 VARCHAR(8), 6~8자리';
COMMENT ON COLUMN pet_mst.species_id       IS 'species_cd FK (NULL = 종 미지정, 시드 데이터 적재 후 NOT NULL 전환)';
COMMENT ON COLUMN pet_mst.profile_photo_id IS 'pet_photo_dtl FK — V6 이후 FK 제약 추가';
COMMENT ON COLUMN pet_mst.deleted_at       IS 'Soft Delete 일시';
