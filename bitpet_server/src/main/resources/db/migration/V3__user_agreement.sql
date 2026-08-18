-- 약관 동의 이력.
--
-- 가입 화면에서 4개 항목을 체크받으면서도 그 사실이 어디에도 저장되지 않고 있었다.
-- 개인정보 보호법은 '무엇에, 언제, 어떤 내용으로' 동의했는지를 증명할 수 있어야 한다고 보고,
-- 정보통신망법은 마케팅 수신에 대해 동의·철회 기록을 따로 요구한다.
-- 체크박스만 있고 기록이 없으면 분쟁이 났을 때 우리가 댈 근거가 없다.
--
-- ⛔ append-only 다. UPDATE·DELETE 하지 말 것.
--    "지금 동의 상태"만 들고 있으면 철회 시점을 증명할 수 없다. 철회도 agreed=false 인
--    새 행으로 남기고, 현재 상태는 (user_id, agreement_cd) 별 최신 행으로 판정한다.
--    사용자가 탈퇴해도 이 행은 CASCADE 로 지워지지만, 그건 의도된 것이다 —
--    동의 기록의 목적은 개인정보 처리의 근거이고 처리를 그만두면 근거도 보관할 이유가 없다.

CREATE TABLE user_agreement_dtl (
    id            BIGSERIAL    PRIMARY KEY,
    user_id       BIGINT       NOT NULL REFERENCES user_mst (id) ON DELETE CASCADE,
    agreement_cd  VARCHAR(20)  NOT NULL,
    version       VARCHAR(20)  NOT NULL,
    agreed        BOOLEAN      NOT NULL,
    source_cd     VARCHAR(20)  NOT NULL,
    agreed_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT ck_user_agreement_cd CHECK (
        agreement_cd IN ('TOS', 'PRIVACY', 'AGE_14', 'MARKETING')),
    CONSTRAINT ck_user_agreement_source CHECK (
        source_cd IN ('SIGNUP', 'OAUTH_SIGNUP', 'SETTINGS', 'REAGREEMENT'))
);

-- 현재 동의 상태 조회가 주 용도: user_id 로 좁힌 뒤 항목별 최신 행을 집는다.
CREATE INDEX idx_user_agreement_user
    ON user_agreement_dtl (user_id, agreement_cd, agreed_at DESC);

COMMENT ON TABLE  user_agreement_dtl IS '약관 동의 이력 (append-only, 철회도 행으로 남김)';
COMMENT ON COLUMN user_agreement_dtl.agreement_cd IS
    'TOS=이용약관 / PRIVACY=개인정보 처리방침 / AGE_14=만14세이상 / MARKETING=마케팅 수신(선택)';
COMMENT ON COLUMN user_agreement_dtl.version IS
    '동의한 약관의 시행일. 개정 후 재동의를 받으면 새 버전으로 행이 하나 더 쌓인다';
COMMENT ON COLUMN user_agreement_dtl.agreed IS
    'true=동의, false=철회 또는 미동의. 철회는 UPDATE 가 아니라 새 행';
COMMENT ON COLUMN user_agreement_dtl.source_cd IS
    '동의를 받은 경로. SIGNUP=이메일 가입 / OAUTH_SIGNUP=소셜 최초 가입 / SETTINGS=마이페이지 / REAGREEMENT=약관 개정 재동의';
COMMENT ON COLUMN user_agreement_dtl.agreed_at IS
    '동의(또는 철회) 시각. 증명의 핵심이라 created_at 과 별도로 둔다';
