-- =============================================================================
-- V55: NFC 태그 바인딩 이력
--
--   nfc_tag_mst 는 "지금 어느 개체에 붙어 있는가" 하나만 들고 있다. 그 값은
--   재연결(rebind)마다 덮어써지므로, 태그가 어느 개체를 거쳐 왔는지는 남지 않는다.
--
--   이력이 필요한 이유는 분쟁 대응이다. 실물 태그는 손에서 손으로 넘어가고
--   (개체 양도·중고 거래·분실), "내 태그를 남이 가로챘다"는 신고가 들어오면
--   현재 상태만으로는 아무것도 판정할 수 없다. 언제 누가 어느 개체에 붙였는지가
--   남아 있어야 한다.
--
--   append-only 다. UPDATE·DELETE 하지 않는다 — 고쳐 쓸 수 있는 이력은 증거가 아니다.
-- =============================================================================

CREATE TABLE nfc_tag_bind_hst (
    id          BIGSERIAL   PRIMARY KEY,
    tag_cd      VARCHAR(10) NOT NULL,
    action      VARCHAR(20) NOT NULL,
    -- 이 액션 이후의 연결 대상. UNBIND/REVOKE 면 NULL
    pet_id      BIGINT,
    -- 이 액션 직전의 연결 대상. BIND(최초 연결)면 NULL, REBIND 면 이전 개체
    prev_pet_id BIGINT,
    -- 액션을 일으킨 사람. 어드민 차단(REVOKE)이나 탈퇴 정리처럼 주체가 없으면 NULL
    actor_id    BIGINT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- FK 를 걸지 않는다. 개체는 물리 삭제되고(탈퇴 정리) 유저도 사라지지만,
-- 이력은 그 뒤에도 남아야 한다. FK 를 걸면 삭제가 이력을 끌고 간다.

-- 조회 축은 하나뿐이다: "이 태그가 어디를 거쳐 왔나"
CREATE INDEX idx_nfc_tag_bind_hst_tag ON nfc_tag_bind_hst (tag_cd, id DESC);

ALTER TABLE nfc_tag_bind_hst
    ADD CONSTRAINT ck_nfc_tag_bind_hst_action
        CHECK (action IN ('BIND', 'REBIND', 'UNBIND', 'REVOKE'));

COMMENT ON TABLE  nfc_tag_bind_hst             IS 'NFC 태그 연결 이력 (append-only). 태그 소유권 분쟁 판정 근거';
COMMENT ON COLUMN nfc_tag_bind_hst.action      IS 'BIND 최초연결 / REBIND 다른 개체로 이전 / UNBIND 해제 / REVOKE 차단';
COMMENT ON COLUMN nfc_tag_bind_hst.prev_pet_id IS '이 액션 직전에 붙어 있던 개체. REBIND 분쟁의 핵심 값';
COMMENT ON COLUMN nfc_tag_bind_hst.actor_id    IS '액션 주체. 어드민 차단·탈퇴 정리처럼 사용자 행위가 아니면 NULL';
