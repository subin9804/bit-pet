-- =============================================================================
-- V44: 사육 그룹 모델 완전 제거 (pet_keeper_rls 로 대체 완료 후)
--   - pet_mst.group_id, routine_mst.group_id 제거
--   - breeding_group_user_rls, breeding_group_mst 제거
--   - 그룹 개념은 스키마 어디에도 남기지 않는다
-- =============================================================================

-- 1. 개체 group_id 제거
DROP INDEX IF EXISTS idx_pet_mst_group_id;
ALTER TABLE pet_mst      DROP CONSTRAINT IF EXISTS fk_pet_mst_group;
ALTER TABLE pet_mst      DROP COLUMN IF EXISTS group_id;

-- 2. 루틴 group_id 제거
DROP INDEX IF EXISTS idx_routine_mst_group_active;
ALTER TABLE routine_mst  DROP CONSTRAINT IF EXISTS fk_routine_mst_group;
ALTER TABLE routine_mst  DROP COLUMN IF EXISTS group_id;

-- 3. 그룹 테이블 제거 (자식 → 부모 순)
DROP TABLE IF EXISTS breeding_group_user_rls;
DROP TABLE IF EXISTS breeding_group_mst;
