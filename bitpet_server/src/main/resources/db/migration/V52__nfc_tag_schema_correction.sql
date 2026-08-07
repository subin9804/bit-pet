-- =============================================================================
-- V52: nfc_tag_mst 스키마 정정
--   1. default_action_cd 제거 — 축이 잘못됐다.
--      작업 종류는 태그가 아니라 '그날의 작업'에 종속된다. 급여일엔 전부 급여,
--      체중 측정일엔 전부 체중이다. 태그마다 동작을 고정해두면 오히려 방해가 된다.
--   2. scan_cnt / last_scan_at 제거 — 조회 경로에 쓰기가 생긴다.
--      스캔 사용률은 앱 애널리틱스 이벤트로 보고 서버에 저장하지 않는다.
--      → 태그 조회 API 는 완전한 read-only 가 된다.
--   3. tag_cd 포맷 확정 — Crockford Base32(I/L/O/U 제외) 6자.
--
-- V51 에서 이미 처리된 항목이 있어 DROP 은 전부 IF EXISTS 로 쓴다
-- (V51 을 적용하지 않은 DB 에서도 이 파일 하나로 같은 결과에 도달해야 한다).
-- =============================================================================

-- 1. 태그별 고정 동작 제거 -----------------------------------------------------
ALTER TABLE nfc_tag_mst DROP CONSTRAINT IF EXISTS ck_nfc_tag_mst_action;
ALTER TABLE nfc_tag_mst DROP COLUMN     IF EXISTS default_action_cd;

-- 2. 스캔 카운터 제거 ----------------------------------------------------------
ALTER TABLE nfc_tag_mst DROP COLUMN IF EXISTS scan_cnt;
ALTER TABLE nfc_tag_mst DROP COLUMN IF EXISTS last_scan_at;

-- 3. tag_cd 포맷 -------------------------------------------------------------
-- 구 코드 풀은 L/U 를 허용했다. 실물에 굽힌 코드는 되돌릴 수 없으므로 조용히
-- 지우지 않고, 위반 행이 있으면 무엇이 걸렸는지 알려주고 멈춘다.
DO $$
DECLARE bad TEXT;
BEGIN
    SELECT string_agg(tag_cd, ', ') INTO bad
      FROM nfc_tag_mst
     WHERE tag_cd !~ '^[0-9A-HJKMNP-TV-Z]{6}$';

    IF bad IS NOT NULL THEN
        RAISE EXCEPTION
            '새 코드 형식(Crockford Base32 6자)을 위반하는 태그가 있습니다: %. '
            '아직 실물에 굽지 않은 재고면 삭제 후 재발급하고, 이미 굽힌 코드면 이 마이그레이션을 조정하세요.', bad;
    END IF;
END $$;

ALTER TABLE nfc_tag_mst DROP CONSTRAINT IF EXISTS ck_nfc_tag_mst_cd_upper;
ALTER TABLE nfc_tag_mst DROP CONSTRAINT IF EXISTS ck_nfc_tag_mst_cd_format;

ALTER TABLE nfc_tag_mst
    -- 서비스단 toUpperCase() 정규화가 빠진 경로로 소문자가 들어오면 PK 가 갈라져
    -- 같은 태그가 두 행이 된다. DB 에서도 막는다.
    ADD CONSTRAINT ck_nfc_tag_mst_cd_upper  CHECK (tag_cd = UPPER(tag_cd)),
    ADD CONSTRAINT ck_nfc_tag_mst_cd_format CHECK (tag_cd ~ '^[0-9A-HJKMNP-TV-Z]{6}$');

COMMENT ON COLUMN nfc_tag_mst.tag_cd IS '태그에 굽는 코드. 랜덤 6자(I/L/O/U 제외). 순차 부여 금지(주소 추측 방지)';
