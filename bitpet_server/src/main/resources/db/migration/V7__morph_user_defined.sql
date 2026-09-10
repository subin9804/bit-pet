-- V7__morph_user_defined.sql
-- 사용자 정의 모프 — 카탈로그(254종)에 없는 조합 모프를 직접 입력할 수 있게 한다.
--
-- 설계 의도: pet_morph_rls / PetResponse.morphs / Flutter Morph 모델을 그대로 두기 위해
-- 별도 테이블을 만들지 않고 morph_cd 에 소유자 플래그만 얹는다. 커스텀 모프도 결국
-- morph_cd 행이므로 개체-모프 연결은 기존 FK 경로를 그대로 탄다.
--
-- 조회 규칙: GET /species/{id}/morphs 는 is_user_defined = false(공식 카탈로그) 이거나
-- created_by = 요청자 인 행만 돌려준다. 남이 만든 커스텀 모프는 보이지 않는다.

ALTER TABLE morph_cd
    ADD COLUMN is_user_defined boolean DEFAULT false NOT NULL,
    ADD COLUMN created_by      bigint;

COMMENT ON COLUMN morph_cd.is_user_defined IS '사용자가 직접 입력한 모프 여부 (false = 공식 카탈로그)';
COMMENT ON COLUMN morph_cd.created_by      IS '커스텀 모프 생성자 user_mst.id (공식 카탈로그는 NULL)';

ALTER TABLE morph_cd
    ADD CONSTRAINT fk_morph_cd_created_by
        FOREIGN KEY (created_by) REFERENCES user_mst (id) ON DELETE SET NULL;

-- 커스텀 모프 목록 조회용. 공식 카탈로그(대다수)는 인덱스에서 제외해 크기를 줄인다.
CREATE INDEX idx_morph_cd_created_by
    ON morph_cd USING btree (created_by, species_id)
    WHERE is_user_defined = true;

-- 정합성 가드: 커스텀이면 생성자가 있어야 하고, 공식 카탈로그면 없어야 한다.
-- created_by 가 ON DELETE SET NULL 이므로 탈퇴 시 커스텀 모프가 이 제약을 깨지 않도록
-- is_user_defined = true AND created_by IS NULL(주인 없는 커스텀) 은 허용한다.
ALTER TABLE morph_cd
    ADD CONSTRAINT ck_morph_cd_user_defined
        CHECK (is_user_defined = true OR created_by IS NULL);
