-- =============================================================================
-- V46: pet_share_invitation.batch_id — 여러 개체를 한 번에 초대(벌크)
--   - 한 번의 벌크 초대로 생성된 N건의 초대 행이 동일한 batch_id 를 공유
--   - 받은 초대함에서 batch_id 로 묶어 "○○님이 N마리 초대"로 표시,
--     한 번에 수락/거절 처리
--   - 단건 초대도 고유 batch_id 1건으로 취급 (일관성)
-- =============================================================================

ALTER TABLE pet_share_invitation ADD COLUMN batch_id UUID;

-- 기존 초대(있다면) 각각 고유 배치로 백필
UPDATE pet_share_invitation SET batch_id = gen_random_uuid() WHERE batch_id IS NULL;

ALTER TABLE pet_share_invitation ALTER COLUMN batch_id SET NOT NULL;

-- 배치 단위 조회(수락/거절, 받은함 그룹핑)
CREATE INDEX idx_pet_share_inv_batch
    ON pet_share_invitation(batch_id);
