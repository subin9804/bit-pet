-- =============================================================================
-- V45: pet_share_invitation 초대 만료 도입
--   - expires_at: 초대 만료 시각 (생성 시 +7일)
--   - status에 'EXPIRED' 허용값 추가
--   - Lazy 판정: 수락·조회 시점에 만료면 EXPIRED로 전환 (배치 스케줄러 없음)
-- =============================================================================

-- 1) 만료 컬럼 추가 (기존 행은 created_at + 7일로 백필)
ALTER TABLE pet_share_invitation
    ADD COLUMN expires_at TIMESTAMPTZ;

UPDATE pet_share_invitation
    SET expires_at = created_at + INTERVAL '7 days'
    WHERE expires_at IS NULL;

ALTER TABLE pet_share_invitation
    ALTER COLUMN expires_at SET NOT NULL;

-- 2) status CHECK 제약에 EXPIRED 추가
ALTER TABLE pet_share_invitation
    DROP CONSTRAINT chk_pet_share_inv_status;

ALTER TABLE pet_share_invitation
    ADD CONSTRAINT chk_pet_share_inv_status
    CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELED', 'EXPIRED'));
