-- 해칭일 정밀도 컬럼 추가
-- 'DAY'  : 정확한 날짜 (기존 동작, 기본값)
-- 'MONTH': 연·월만 입력 (일은 01로 저장)
ALTER TABLE pet_mst
    ADD COLUMN hatching_date_precision VARCHAR(5) DEFAULT 'DAY';
