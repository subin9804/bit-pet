-- V19__routine_cycle_mode.sql
-- 루틴 반복 방식 — '며칠마다'(INTERVAL) 외에 '요일 지정'(WEEKDAY)·'날짜 지정'(MONTHDAY)
--
-- 앱 폼에는 요일·날짜 모드가 있었지만 서버에 받을 칸이 없어 cycle_days 하나로 뭉개졌다
-- (월·수·금 → 1 = 매일, 매월 N일 → 30 = 월 1회). 저장된 행에서 원래 선택을 되살릴 수 없으므로
-- 기존 행은 전부 INTERVAL 로 둔다 — 사용자가 다시 고르면 된다.
--
-- 요일·날짜는 CSV 문자열이다 (배열 컬럼은 Hibernate 스키마 검증과 버전마다 어긋날 위험이 있다).
--   cycle_days_of_week  : ISO 요일 1=월 … 7=일          예) '1,3,5'
--   cycle_days_of_month : 1~31, 32 = 그 달의 말일        예) '1,15,32'
-- cycle_days 는 계속 NOT NULL 로 남긴다 — 미루기 프리셋의 '한 주기' 길이로 쓰인다
-- (WEEKDAY=7, MONTHDAY=30).

ALTER TABLE routine_mst
    ADD COLUMN IF NOT EXISTS cycle_mode          VARCHAR(10) NOT NULL DEFAULT 'INTERVAL',
    ADD COLUMN IF NOT EXISTS cycle_days_of_week  VARCHAR(20),
    ADD COLUMN IF NOT EXISTS cycle_days_of_month VARCHAR(100);

ALTER TABLE routine_mst
    ADD CONSTRAINT ck_routine_mst_cycle_mode
        CHECK (cycle_mode IN ('INTERVAL', 'WEEKDAY', 'MONTHDAY')),
    ADD CONSTRAINT ck_routine_mst_cycle_days_of_week
        CHECK (cycle_days_of_week IS NULL OR cycle_days_of_week ~ '^[1-7](,[1-7])*$'),
    ADD CONSTRAINT ck_routine_mst_cycle_days_of_month
        CHECK (cycle_days_of_month IS NULL
               OR cycle_days_of_month ~ '^([1-9]|[12][0-9]|3[0-2])(,([1-9]|[12][0-9]|3[0-2]))*$'),
    -- 모드마다 쓰는 칸이 정해져 있다. 안 쓰는 칸에 값이 남으면 모드를 바꿨을 때 옛 선택이 되살아난다
    ADD CONSTRAINT ck_routine_mst_cycle_fields_by_mode
        CHECK (
            (cycle_mode = 'INTERVAL' AND cycle_days_of_week IS NULL AND cycle_days_of_month IS NULL)
         OR (cycle_mode = 'WEEKDAY'  AND cycle_days_of_week IS NOT NULL AND cycle_days_of_month IS NULL)
         OR (cycle_mode = 'MONTHDAY' AND cycle_days_of_month IS NOT NULL AND cycle_days_of_week IS NULL)
        );

COMMENT ON COLUMN routine_mst.cycle_mode          IS '반복 방식: INTERVAL(cycle_days 마다) / WEEKDAY(요일 지정) / MONTHDAY(매월 날짜 지정)';
COMMENT ON COLUMN routine_mst.cycle_days_of_week  IS 'WEEKDAY 전용 — ISO 요일 CSV (1=월 … 7=일)';
COMMENT ON COLUMN routine_mst.cycle_days_of_month IS 'MONTHDAY 전용 — 날짜 CSV (1~31, 32=말일). 그 달에 없는 날(2/30 등)은 건너뛴다';
