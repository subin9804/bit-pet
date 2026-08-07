-- =============================================================================
-- V51: nfc_tag_mst 보완 — 칩 세대 / 생산 배치 / 유통 상태 + 코드 형식 제약
--   · 실물 태그가 NTAG203 으로 입고됨. 패스워드 보호가 불가능한 세대라
--     "락 미적용 출고"라는 사실을 재고 단위로 기록해 둔다 (회수 판단 근거).
--   · scan_cnt / last_scan_at 제거 — 스캔마다 UPDATE 가 도는 구조라 MVP 범위에서 뺀다.
--     사용률은 서버에 쌓지 않고 클라이언트 애널리틱스 이벤트로 대체한다.
--   · 기존 코드는 'BP' + 랜덤 4자였고, 신규는 접두사 없이 랜덤 6자다.
--     둘 다 대문자 6자라 아래 형식 CHECK 를 그대로 통과한다 (기존 재고 폐기 불필요).
-- =============================================================================

ALTER TABLE nfc_tag_mst
    ADD COLUMN chip_type VARCHAR(20) NOT NULL DEFAULT 'NTAG203',
    ADD COLUMN batch_no  VARCHAR(20) NULL,
    ADD COLUMN status    VARCHAR(20) NOT NULL DEFAULT 'STOCK';

-- 기존 행의 상태는 연결 이력에서 그대로 유도된다
UPDATE nfc_tag_mst
   SET status = CASE
                    WHEN pet_id    IS NOT NULL THEN 'BOUND'
                    WHEN linked_at IS NOT NULL THEN 'SOLD'
                    ELSE 'STOCK'
                END;

ALTER TABLE nfc_tag_mst
    ADD CONSTRAINT ck_nfc_tag_mst_status    CHECK (status IN ('STOCK', 'SOLD', 'BOUND', 'REVOKED')),
    -- 서비스단 normalize(toUpperCase) 가 누락된 경로로 소문자 코드가 들어오면
    -- PK 가 갈라져 같은 태그가 두 행이 된다. DB 에서도 막는다.
    ADD CONSTRAINT ck_nfc_tag_mst_cd_upper  CHECK (tag_cd = UPPER(tag_cd)),
    ADD CONSTRAINT ck_nfc_tag_mst_cd_format CHECK (tag_cd ~ '^[0-9A-Z]{6}$');

ALTER TABLE nfc_tag_mst
    DROP COLUMN scan_cnt,
    DROP COLUMN last_scan_at;

CREATE INDEX idx_nfc_tag_mst_status ON nfc_tag_mst (status);
-- 불량 회수는 배치 단위로 훑는다. NULL(배치 미상 구재고)은 조회 대상이 아니라 제외.
CREATE INDEX idx_nfc_tag_mst_batch  ON nfc_tag_mst (batch_no) WHERE batch_no IS NOT NULL;

COMMENT ON COLUMN nfc_tag_mst.tag_cd    IS '태그에 굽는 코드. 랜덤 대문자 6자. 순차 부여 금지(주소 추측 방지)';
COMMENT ON COLUMN nfc_tag_mst.chip_type IS '칩 세대. NTAG203은 패스워드 보호 불가(락 미적용 출고)';
COMMENT ON COLUMN nfc_tag_mst.batch_no  IS '생산 배치. 불량 회수 단위';
COMMENT ON COLUMN nfc_tag_mst.status    IS 'STOCK=미판매 재고 / SOLD=판매됐으나 미연결 / BOUND=개체 연결됨 / REVOKED=분실·복제 사고로 영구 차단';
