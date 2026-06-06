-- =============================================================================
-- V25: feeding_dtl 재구성
-- - feed_response 제거 (미사용)
-- - size_label 추가 (XS/S/M/L/XL/XXL 또는 극소/소/중/대, nullable)
-- - supplement 추가 (CALCIUM/PROBIOTIC/VITAMIN/OTHER, nullable)
-- =============================================================================

-- 기존 feed_response 제약 및 컬럼 제거
ALTER TABLE feeding_dtl DROP CONSTRAINT IF EXISTS ck_feeding_dtl_response;
ALTER TABLE feeding_dtl DROP COLUMN IF EXISTS feed_response;

-- size_label: 마우스 등 크기별 먹이의 사이즈 표기 (프론트엔드 관리)
ALTER TABLE feeding_dtl ADD COLUMN size_label VARCHAR(10) NULL;

-- supplement: 영양제 종류 (급여와 함께 선택적으로 기록)
ALTER TABLE feeding_dtl ADD COLUMN supplement VARCHAR(20) NULL;

ALTER TABLE feeding_dtl
    ADD CONSTRAINT ck_feeding_dtl_supplement
        CHECK (supplement IN ('CALCIUM', 'PROBIOTIC', 'VITAMIN', 'OTHER') OR supplement IS NULL);

COMMENT ON COLUMN feeding_dtl.size_label  IS '먹이 크기 레이블 (XS/S/M/L/XL/XXL, 극소/소/중/대 등) — 프론트 관리';
COMMENT ON COLUMN feeding_dtl.supplement  IS '영양제: CALCIUM/PROBIOTIC/VITAMIN/OTHER (nullable)';
