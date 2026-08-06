-- =============================================================================
-- V50: feeding_dtl 거식(먹이 거부) 기록
-- - refused_yn 추가. 'Y' 면 먹이를 거부한 기록 → food_type 이 없다.
-- - 그래서 food_type 의 NOT NULL 을 풀고, 대신 CHECK 로 둘을 묶는다.
--   (거식인데 먹이 종류가 있거나, 급여인데 먹이 종류가 없는 행을 막는다)
-- =============================================================================

ALTER TABLE feeding_dtl ADD COLUMN refused_yn VARCHAR(1) NOT NULL DEFAULT 'N';

ALTER TABLE feeding_dtl
    ADD CONSTRAINT ck_feeding_dtl_refused_yn
        CHECK (refused_yn IN ('Y', 'N'));

ALTER TABLE feeding_dtl ALTER COLUMN food_type DROP NOT NULL;

-- 기존 행은 전부 refused_yn='N' + food_type NOT NULL 이라 그대로 통과한다.
ALTER TABLE feeding_dtl
    ADD CONSTRAINT ck_feeding_dtl_food_type_by_refused
        CHECK ((refused_yn = 'Y' AND food_type IS NULL)
            OR (refused_yn = 'N' AND food_type IS NOT NULL));

-- 개체별 거식 이력 조회 (식욕 저하 추적) — 거식 행만 담는 부분 인덱스
CREATE INDEX idx_feeding_dtl_refused
    ON feeding_dtl (pet_id, fed_at DESC)
    WHERE refused_yn = 'Y' AND deleted_at IS NULL;

COMMENT ON COLUMN feeding_dtl.refused_yn IS '거식 여부: Y=먹이 거부(food_type NULL, 메모만), N=일반 급여';
