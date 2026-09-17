-- 만 14세 미만 아동 계정 + 보호자 동의.
--
-- 지금까지는 AGE_14 를 필수 동의로 받아 만 14세 미만을 아예 막고 있었다.
-- 개인정보 보호법 제22조의2 는 만 14세 미만 아동의 개인정보를 처리하려면 법정대리인의
-- 동의를 받으라고 한다. 그 절차가 없어서 막았던 것이고, 이제 절차를 만든다.
--
-- ⚖️ 동의 방식은 '보호자 계정이 자녀 계정을 만든다' 로 정했다.
--    보호자 이메일로 동의 링크를 보내는 방식이 국내 표준이지만, 아동이 아무 이메일이나
--    적어 넣으면 그대로 통과한다 — 동의를 받은 척하는 기록만 쌓인다.
--    보호자가 이미 로그인한 세션에서 직접 만들면 동의 주체가 화면 앞에 실재한다.

-- ── 1. user_mst: 생년월일과 보호자 ────────────────────────────────────
--
-- birth_date 는 NULL 을 허용한다. 기존 사용자는 생년월일을 준 적이 없고,
-- 가입 시 AGE_14 자기신고로 만 14세 이상임을 확인했다 — NULL = '성인(자기신고)' 이다.
-- ⚠️ 그러므로 "미성년 여부"를 birth_date IS NULL 로 판정하지 말 것. NULL 은 성인이다.
ALTER TABLE user_mst ADD COLUMN birth_date DATE;

-- 보호자. 자녀 계정만 값이 있다.
-- ON DELETE RESTRICT 인 이유: 보호자가 탈퇴하면 자녀 계정은 법정대리인 동의의 근거를
-- 잃는다. 조용히 NULL 이 되어 '보호자 없는 아동 계정'으로 남는 쪽이 훨씬 위험하므로,
-- 탈퇴 경로가 자녀 계정을 먼저 처리하도록 DB 가 막는다.
ALTER TABLE user_mst ADD COLUMN guardian_user_id BIGINT
    REFERENCES user_mst (id) ON DELETE RESTRICT;

-- 보호자가 자기 자녀를 조회하는 경로
CREATE INDEX idx_user_guardian ON user_mst (guardian_user_id)
    WHERE guardian_user_id IS NOT NULL;

-- 자기 자신을 보호자로 걸 수 없다
ALTER TABLE user_mst ADD CONSTRAINT ck_user_guardian_not_self
    CHECK (guardian_user_id IS NULL OR guardian_user_id <> id);

COMMENT ON COLUMN user_mst.birth_date IS
    '생년월일. NULL = 기존 사용자(가입 시 AGE_14 자기신고로 만 14세 이상 확인). 만 14세 미만 판정에만 쓴다';
COMMENT ON COLUMN user_mst.guardian_user_id IS
    '법정대리인 user_id. 자녀 계정만 값이 있다. 보호자 탈퇴 시 RESTRICT — 자녀를 먼저 처리해야 한다';

-- ── 2. 보호자 동의 기록 ───────────────────────────────────────────────
--
-- user_agreement_dtl 은 append-only 다(V3). 보호자 동의도 같은 테이블에 쌓는다 —
-- "무엇에, 언제, 어떤 경로로 동의했는가"를 한 곳에서 답할 수 있어야 한다.
-- 행의 user_id 는 '동의의 대상이 되는 사람' 즉 자녀다. 누가 눌렀는지는 자녀의
-- guardian_user_id 를 따라가면 나온다.
ALTER TABLE user_agreement_dtl DROP CONSTRAINT ck_user_agreement_cd;
ALTER TABLE user_agreement_dtl ADD CONSTRAINT ck_user_agreement_cd CHECK (
    agreement_cd IN ('TOS', 'PRIVACY', 'AGE_14', 'MARKETING', 'GUARDIAN'));

ALTER TABLE user_agreement_dtl DROP CONSTRAINT ck_user_agreement_source;
ALTER TABLE user_agreement_dtl ADD CONSTRAINT ck_user_agreement_source CHECK (
    source_cd IN ('SIGNUP', 'OAUTH_SIGNUP', 'SETTINGS', 'REAGREEMENT', 'GUARDIAN_CONSENT'));

COMMENT ON COLUMN user_agreement_dtl.agreement_cd IS
    'TOS=이용약관 / PRIVACY=개인정보 처리방침 / AGE_14=만14세이상 / MARKETING=마케팅 수신(선택) / GUARDIAN=법정대리인 동의';
COMMENT ON COLUMN user_agreement_dtl.source_cd IS
    'SIGNUP=이메일 가입 / OAUTH_SIGNUP=소셜 최초 가입 / SETTINGS=마이페이지 / REAGREEMENT=약관 개정 재동의 / GUARDIAN_CONSENT=보호자가 자녀 계정을 만들며 동의';

-- ── 3. 아동 전용 게시판 ───────────────────────────────────────────────
--
-- 아동 계정은 여기서만 글·댓글·좋아요를 남길 수 있고, 성인 계정은 이 게시판을
-- 읽지도 쓰지도 못한다.
--
-- ⛔ "성인도 읽기만 되게" 로 완화하지 말 것. 아동만 모인 공간이 성인에게 열려 있으면
--    그 자체가 아동에게 접근하는 통로가 된다. 읽을 수 있는 건 아동 본인들과 운영자뿐이다.
--    (보호자는 자녀 계정을 통해서가 아니라 '자녀 활동 보기'로 감독한다.)
--
-- display_order = 5 지만 성인에게는 목록 자체가 내려가지 않으므로 순서는 아동 화면에서만 의미가 있다.
INSERT INTO post_category_cd (id, code, name_ko, description, display_order, is_active) VALUES
    (6, 'KIDS', '어린이 게시판', '만 14세 미만 회원만 쓰고 볼 수 있는 게시판', 5, TRUE);

SELECT setval('post_category_cd_id_seq', 6, TRUE);
