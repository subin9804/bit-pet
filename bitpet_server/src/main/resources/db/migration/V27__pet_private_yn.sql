-- V27: pet_mst에 private_yn 컬럼 추가
-- 'Y' = 비공개(전체 검색 불가, 기본값), 'N' = 공개(전체 검색 허용)

ALTER TABLE pet_mst
    ADD COLUMN private_yn CHAR(1) NOT NULL DEFAULT 'Y'
        CONSTRAINT chk_pet_private_yn CHECK (private_yn IN ('Y', 'N'));
