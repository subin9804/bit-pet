-- 개발자에게 문의하기 (2026-11-14)
--
-- 답장이 없는 일방향 건의함이다. 운영자는 DB 를 직접 본다 — 메일 알림도, 관리자 화면도 없다.
-- 앱 버전·OS 는 앱이 같이 보낸다. 버그 제보는 "어느 버전에서" 를 모르면 재현할 수 없다.
--
-- 탈퇴하면 함께 지운다 (AuthService.withdraw). 본문에 개인정보가 섞일 수 있는 자유 입력이다.
CREATE TABLE inquiry_dtl (
    id          bigserial PRIMARY KEY,
    user_id     bigint        NOT NULL REFERENCES user_mst(id) ON DELETE CASCADE,
    category    varchar(20)   NOT NULL,
    content     varchar(2000) NOT NULL,
    app_version varchar(30),
    platform    varchar(10),
    os_version  varchar(100),
    created_at  timestamptz   NOT NULL DEFAULT now(),
    updated_at  timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT ck_inquiry_dtl_category CHECK (category IN ('BUG', 'SUGGESTION', 'ACCOUNT', 'ETC'))
);

CREATE INDEX idx_inquiry_dtl_user_created ON inquiry_dtl (user_id, created_at);

COMMENT ON TABLE inquiry_dtl IS '개발자에게 문의하기 — 답장 없는 일방향 건의함. 운영자가 DB 로 직접 본다';
COMMENT ON COLUMN inquiry_dtl.category IS 'BUG 오류 제보 / SUGGESTION 기능 제안 / ACCOUNT 계정 / ETC 기타';
COMMENT ON COLUMN inquiry_dtl.app_version IS '보낸 앱 버전 (예: 1.0.0+3). 버그 재현용';
