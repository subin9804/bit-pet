-- =============================================================================
-- V24: 사육 그룹 (breeding_group_mst, breeding_group_user_rls, pet_mst.group_id)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. 그룹 마스터
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE breeding_group_mst (
    id          BIGSERIAL    PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    invite_code CHAR(6)      NOT NULL,
    owner_id    BIGINT       NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ  NULL,

    CONSTRAINT fk_breeding_group_owner FOREIGN KEY (owner_id) REFERENCES user_mst(id)
);

-- 초대코드 유일성 (활성 그룹에만)
CREATE UNIQUE INDEX idx_breeding_group_invite_code
    ON breeding_group_mst(invite_code) WHERE deleted_at IS NULL;

CREATE INDEX idx_breeding_group_owner
    ON breeding_group_mst(owner_id) WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. 유저-그룹 연결 (role: OWNER / MEMBER)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE breeding_group_user_rls (
    group_id    BIGINT      NOT NULL,
    user_id     BIGINT      NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_breeding_group_user
        PRIMARY KEY (group_id, user_id),
    CONSTRAINT fk_breeding_group_user_group
        FOREIGN KEY (group_id) REFERENCES breeding_group_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_breeding_group_user_user
        FOREIGN KEY (user_id)  REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT chk_breeding_group_role
        CHECK (role IN ('OWNER', 'MEMBER'))
);

-- 현재 정책: 유저당 1그룹. 추후 BREEDER 다수그룹 허용 시 이 인덱스만 DROP
CREATE UNIQUE INDEX idx_breeding_group_user_one_group
    ON breeding_group_user_rls(user_id);

-- 그룹별 멤버 목록 조회
CREATE INDEX idx_breeding_group_user_group
    ON breeding_group_user_rls(group_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. 개체에 그룹 FK 추가 (칼럼 방식 — 개체는 role 없음, 항상 M:1)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE pet_mst
    ADD COLUMN group_id BIGINT NULL
        CONSTRAINT fk_pet_mst_group REFERENCES breeding_group_mst(id) ON DELETE SET NULL;

CREATE INDEX idx_pet_mst_group_id
    ON pet_mst(group_id) WHERE group_id IS NOT NULL;
