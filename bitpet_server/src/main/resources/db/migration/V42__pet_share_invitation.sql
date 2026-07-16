-- =============================================================================
-- V42: pet_share_invitation — 개체 공유(SHARE) / 입분양(TRANSFER) 초대
--   - inviter(OWNER)가 invitee(share_code로 지정)에게 초대 생성
--   - invitee 수락 시 단일 트랜잭션으로 pet_keeper_rls 반영
--     SHARE   : invitee를 KEEPER로 추가
--     TRANSFER: invitee를 OWNER로, 기존 OWNER 제거 (pet_mst.user_id 동기화)
-- =============================================================================

CREATE TABLE pet_share_invitation (
    id              BIGSERIAL   PRIMARY KEY,
    pet_id          BIGINT      NOT NULL,
    inviter_user_id BIGINT      NOT NULL,
    invitee_user_id BIGINT      NOT NULL,
    invite_type     VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at    TIMESTAMPTZ NULL,

    CONSTRAINT fk_pet_share_inv_pet     FOREIGN KEY (pet_id)          REFERENCES pet_mst(id)  ON DELETE CASCADE,
    CONSTRAINT fk_pet_share_inv_inviter FOREIGN KEY (inviter_user_id) REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_pet_share_inv_invitee FOREIGN KEY (invitee_user_id) REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT chk_pet_share_inv_type   CHECK (invite_type IN ('SHARE', 'TRANSFER')),
    CONSTRAINT chk_pet_share_inv_status CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELED'))
);

-- 받은 초대함 조회
CREATE INDEX idx_pet_share_inv_invitee
    ON pet_share_invitation(invitee_user_id, status);

-- 보낸 초대 조회
CREATE INDEX idx_pet_share_inv_pet
    ON pet_share_invitation(pet_id, status);

-- 동일 개체·동일 대상 PENDING 중복 방지
CREATE UNIQUE INDEX idx_pet_share_inv_pending
    ON pet_share_invitation(pet_id, invitee_user_id) WHERE status = 'PENDING';
