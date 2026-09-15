-- V8__species_category_mammal.sql
-- 종 대분류에 포유류(M) 추가 — 아프리카 겨울잠쥐·시리안햄스터·몽골리안 저빌·친칠라 (Notion morph_cd v1.3)
--
-- CHECK 를 넓히는 방향이라 기존 행·구버전 서버 모두 영향 없다.
-- 종 행 자체는 R__01 이 넣는다 (Flyway 는 V 를 R 보다 먼저 적용하므로 이 제약이 먼저 풀린다).

ALTER TABLE species_cd DROP CONSTRAINT ck_species_cd_category;

ALTER TABLE species_cd
    ADD CONSTRAINT ck_species_cd_category
        CHECK (category = ANY (ARRAY['R'::bpchar, 'A'::bpchar, 'M'::bpchar]));

COMMENT ON COLUMN species_cd.category    IS 'R=REPTILE / A=AMPHIBIAN / M=MAMMAL';
COMMENT ON COLUMN species_cd.subcategory IS 'GECKO / LIZARD / CHAMELEON / SNAKE / TURTLE / FROG / NEWT / SMALL_MAMMAL';
