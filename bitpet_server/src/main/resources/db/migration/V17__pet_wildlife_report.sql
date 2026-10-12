-- 야생생물법 신고 여부 (2026-10-13)
--
-- '지정관리 야생동물 보관신고'(관할 지자체, 2025-12-14 시행)와 'CITES 양도·양수 신고'
-- (관할 유역환경청)를 **했는지 안 했는지**만 기억한다. 확인증 번호·신고일·관할청·구비서류는
-- 일부러 받지 않는다 — 신고 접수는 WIMS(wims.mcee.go.kr) 웹 신청뿐이고 공공 API 가
-- 아예 없어서, 앱이 그 값들을 들고 있어도 쓸 데가 없다. 사육자가 "이 개체 신고했나?"를
-- 다시 떠올리지 않게 하는 것이 전부다.
--
-- 두 제도를 플래그 하나로 합치지 않은 이유: 관할과 요건이 다르고, 파충류 CITES II 종은
-- **둘 다 대상**일 수 있다. 하나로 묶으면 둘 중 뭘 했는지가 사라진다.
--
-- 기본값 'N'(안 함). 기존 개체도 전부 'N' 으로 깔린다 — 신고했는지는 서버가 알 길이
-- 없으니 사육자가 직접 켠다. '해당 없음'(대상 종이 아님)은 따로 두지 않았다: 종별 대상
-- 판정(지정관리·CITES 분류군 매핑)이 아직 없어서 지금은 'N' 과 구별할 근거가 없다.
ALTER TABLE pet_mst
    ADD COLUMN keeping_report_yn VARCHAR(1) DEFAULT 'N' NOT NULL,
    ADD COLUMN cites_report_yn   VARCHAR(1) DEFAULT 'N' NOT NULL;

ALTER TABLE pet_mst
    ADD CONSTRAINT chk_pet_keeping_report_yn CHECK (keeping_report_yn IN ('Y', 'N')),
    ADD CONSTRAINT chk_pet_cites_report_yn   CHECK (cites_report_yn   IN ('Y', 'N'));

COMMENT ON COLUMN pet_mst.keeping_report_yn IS '지정관리 야생동물 보관신고 완료 여부(Y/N). 관할 지자체, 접수 API 없음';
COMMENT ON COLUMN pet_mst.cites_report_yn   IS 'CITES 양도·양수 신고 완료 여부(Y/N). 관할 유역환경청, 접수 API 없음';
