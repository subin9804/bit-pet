-- =============================================================================
-- V26: 그룹 초대코드를 영구 DB 컬럼 → 5분 TTL Redis 발급 방식으로 전환
-- =============================================================================

DROP INDEX IF EXISTS idx_breeding_group_invite_code;

ALTER TABLE breeding_group_mst
    DROP COLUMN invite_code;
