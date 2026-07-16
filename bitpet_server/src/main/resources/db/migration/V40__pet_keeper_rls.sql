-- =============================================================================
-- V40: 개체 공유 관계 (pet_keeper_rls) — 그룹 모델 대체
--   - 개체 접근 권한 판정의 단일 소스
--   - role: OWNER(소유자, 개체당 1명) / KEEPER(공유받은 사육자)
--   - pet_mst.user_id는 OWNER 비정규화 사본으로 계속 유지 (기존 쿼리 호환)
-- =============================================================================

CREATE TABLE pet_keeper_rls (
    pet_id    BIGINT      NOT NULL,
    user_id   BIGINT      NOT NULL,
    role      VARCHAR(20) NOT NULL DEFAULT 'KEEPER',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_pet_keeper PRIMARY KEY (pet_id, user_id),
    CONSTRAINT fk_pet_keeper_pet  FOREIGN KEY (pet_id)  REFERENCES pet_mst(id)  ON DELETE CASCADE,
    CONSTRAINT fk_pet_keeper_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT chk_pet_keeper_role CHECK (role IN ('OWNER', 'KEEPER'))
);

-- 개체당 OWNER는 1명
CREATE UNIQUE INDEX idx_pet_keeper_owner
    ON pet_keeper_rls(pet_id) WHERE role = 'OWNER';

-- 유저별 사육 개체 목록 조회
CREATE INDEX idx_pet_keeper_user
    ON pet_keeper_rls(user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 백필: 기존 모든 개체 → 소유자(pet_mst.user_id)를 OWNER 로 등록
--   (soft delete된 개체 포함 — FK 정합성 유지)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO pet_keeper_rls (pet_id, user_id, role, joined_at)
SELECT p.id, p.user_id, 'OWNER', COALESCE(p.created_at, NOW())
FROM pet_mst p
WHERE p.user_id IS NOT NULL;
