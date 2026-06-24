-- =============================================================================
-- V34: 루틴을 사육 그룹 소속으로 전환 (routine_mst.group_id 추가)
--   - 루틴 소속 기준: user → breeding_group
--   - group_id NULL = 그룹 미소속 유저의 개인 루틴 (pet_mst.group_id와 동일 패턴)
-- =============================================================================

-- 1. group_id 컬럼 추가 (그룹 해산 시 SET NULL → 개인 루틴으로 강등)
ALTER TABLE routine_mst
    ADD COLUMN group_id BIGINT NULL
        CONSTRAINT fk_routine_mst_group REFERENCES breeding_group_mst(id) ON DELETE SET NULL;

-- 2. 기존 루틴 백필 — 소유자(user_id)의 현재 그룹으로 채움
--    그룹 미소속 유저의 루틴은 group_id NULL 유지
UPDATE routine_mst r
SET group_id = m.group_id
FROM breeding_group_user_rls m
WHERE m.user_id = r.user_id;

-- 3. 그룹 기준 활성 루틴 조회 인덱스
CREATE INDEX idx_routine_mst_group_active
    ON routine_mst(group_id, is_active) WHERE group_id IS NOT NULL;

COMMENT ON COLUMN routine_mst.group_id IS 'v6: 루틴 소속 사육 그룹 (NULL=개인 루틴). user_id는 생성자로 유지';
