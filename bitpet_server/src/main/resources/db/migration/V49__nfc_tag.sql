-- =============================================================================
-- V49: NFC 태그 이름표
--   · 태그는 자기 코드(tag_cd)만 가지고 출고되고, 개체와의 연결은 이 테이블에만 존재한다.
--   · pet_mst 에 컬럼을 추가하지 않고 별도 테이블로 분리 — 재사용·해제·분실 처리가 깔끔.
--   · 재고 상태 판별
--       pet_id IS NULL AND linked_at IS NULL      → 미판매 재고
--       pet_id IS NULL AND linked_at IS NOT NULL  → 판매되었으나 미연결(온보딩 이탈 의심)
-- =============================================================================

CREATE TABLE nfc_tag_mst (
    tag_cd            VARCHAR(10)  PRIMARY KEY,
    pet_id            BIGINT       NULL,
    user_id           BIGINT       NULL,
    default_action_cd VARCHAR(20)  NOT NULL DEFAULT 'PET_DETAIL',
    linked_at         TIMESTAMPTZ  NULL,
    scan_cnt          INT          NOT NULL DEFAULT 0,
    last_scan_at      TIMESTAMPTZ  NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_nfc_tag_mst_pet  FOREIGN KEY (pet_id)  REFERENCES pet_mst(id)  ON DELETE SET NULL,
    CONSTRAINT fk_nfc_tag_mst_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE SET NULL,
    CONSTRAINT ck_nfc_tag_mst_action CHECK (default_action_cd IN ('PET_DETAIL', 'RECORD_FEEDING', 'RECORD_WEIGHT'))
);

CREATE INDEX idx_nfc_tag_mst_pet  ON nfc_tag_mst (pet_id);
CREATE INDEX idx_nfc_tag_mst_user ON nfc_tag_mst (user_id);

COMMENT ON TABLE  nfc_tag_mst                   IS 'NFC 태그 이름표 — 태그코드와 개체의 연결';
COMMENT ON COLUMN nfc_tag_mst.tag_cd            IS '태그에 굽는 코드. BP + 랜덤 4자 (예: BP7K3M). 순차 부여 금지(주소 추측 방지)';
COMMENT ON COLUMN nfc_tag_mst.pet_id            IS 'NULL = 미판매 재고 또는 연결 해제 상태';
COMMENT ON COLUMN nfc_tag_mst.user_id           IS '소유권. 남의 태그 탈취 방지용';
COMMENT ON COLUMN nfc_tag_mst.default_action_cd IS 'PET_DETAIL / RECORD_FEEDING / RECORD_WEIGHT';
COMMENT ON COLUMN nfc_tag_mst.linked_at         IS '최초 연결 시각. 해제해도 남겨 판매/미연결 구분에 사용';
COMMENT ON COLUMN nfc_tag_mst.scan_cnt          IS '스캔 횟수 — 사용률 모니터링 지표';
