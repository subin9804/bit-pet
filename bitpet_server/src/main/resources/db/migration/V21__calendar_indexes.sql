-- =============================================================================
-- V21: 캘린더 집계 성능용 인덱스 보강
-- 6개 기록 테이블 모두 (pet_id, 시점_컬럼 DESC) WHERE deleted_at IS NULL
-- =============================================================================

-- weight_dtl (기존 인덱스는 partial 아님 → 캘린더용 partial 추가)
CREATE INDEX IF NOT EXISTS idx_weight_dtl_pet_calendar
    ON weight_dtl (pet_id, measured_at DESC) WHERE deleted_at IS NULL;

-- feeding_dtl
CREATE INDEX IF NOT EXISTS idx_feeding_dtl_pet_calendar
    ON feeding_dtl (pet_id, fed_at DESC) WHERE deleted_at IS NULL;

-- cleaning_dtl (partial 보강)
CREATE INDEX IF NOT EXISTS idx_cleaning_dtl_pet_calendar
    ON cleaning_dtl (pet_id, cleaned_at DESC) WHERE deleted_at IS NULL;

-- memo_dtl, mating_dtl, laying_dtl은 V15/V18/V19에서 이미 partial 인덱스 생성됨

COMMENT ON INDEX idx_weight_dtl_pet_calendar   IS '캘린더 집계 쿼리 전용 partial 인덱스';
COMMENT ON INDEX idx_feeding_dtl_pet_calendar  IS '캘린더 집계 쿼리 전용 partial 인덱스';
COMMENT ON INDEX idx_cleaning_dtl_pet_calendar IS '캘린더 집계 쿼리 전용 partial 인덱스';
