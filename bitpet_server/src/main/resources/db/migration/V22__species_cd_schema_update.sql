-- V22__species_cd_schema_update.sql
-- species_cd.category 컬럼 VARCHAR(20)→CHAR(2) 변환 및 인덱스 재구성
-- 이유: Notion v1.1 스펙 = category CHAR(2) ('R'=파충류, 'A'=양서류)
--       V3의 CHECK (category IN ('REPTILE','AMPHIBIAN'))과 충돌 → 수정

-- ─────────────────────────────────────────────
-- 1. pg_trgm 확장 (한국어 명칭 GIN 인덱스 용)
-- ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ─────────────────────────────────────────────
-- 2. 기존 CHECK 제약 제거
-- ─────────────────────────────────────────────
ALTER TABLE species_cd DROP CONSTRAINT ck_species_cd_category;

-- ─────────────────────────────────────────────
-- 3. category 컬럼 타입 변경 VARCHAR(20) → CHAR(2)
--    기존 데이터가 있을 경우 'REPTILE' → 'R', 'AMPHIBIAN' → 'A' 로 변환
-- ─────────────────────────────────────────────
ALTER TABLE species_cd
    ALTER COLUMN category TYPE CHAR(2)
    USING CASE category
              WHEN 'REPTILE'   THEN 'R'
              WHEN 'AMPHIBIAN' THEN 'A'
              ELSE category
          END;

-- ─────────────────────────────────────────────
-- 4. 새 CHECK 제약 추가
-- ─────────────────────────────────────────────
ALTER TABLE species_cd
    ADD CONSTRAINT ck_species_cd_category CHECK (category IN ('R', 'A'));

-- ─────────────────────────────────────────────
-- 5. 기존 인덱스 제거 (V3 생성분)
-- ─────────────────────────────────────────────
DROP INDEX IF EXISTS idx_species_cd_category;
DROP INDEX IF EXISTS idx_species_cd_display_order;

-- ─────────────────────────────────────────────
-- 6. 새 인덱스 추가
-- ─────────────────────────────────────────────

-- 종 선택 모달: category + is_active 필터 + display_order 정렬
CREATE INDEX idx_species_cd_category_order
    ON species_cd (category, is_active, display_order);

-- subcategory 탭 필터링
CREATE INDEX idx_species_cd_subcategory
    ON species_cd (subcategory, is_active);

-- 한국어 명칭 부분 일치 검색 (pg_trgm GIN)
CREATE INDEX idx_species_cd_name_ko_trgm
    ON species_cd USING gin (name_ko gin_trgm_ops);
