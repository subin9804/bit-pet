-- V11__community_report_block.sql
-- 커뮤니티 신고 · 차단.
--
-- 커뮤니티에 사용자 글·댓글·사진이 올라가는데 신고할 방법도, 특정 사용자를 안 볼 방법도
-- 없었다. 이건 기능 부족이 아니라 스토어 정책·아동 보호 요건을 못 맞추는 상태다.
--
-- 두 기능은 목적이 다르다.
--   · 차단(user_block_rls)  = "나는 이 사람을 안 볼래"  — 운영자에게 아무것도 가지 않는다
--   · 신고(post_report_dtl) = "운영자가 판단해 주세요" — 접수와 동시에 신고자 쪽 차단도 건다
-- 신고했는데 그 글이 계속 보이면 신고한 의미가 없어서, 신고는 항상 차단을 동반한다.
-- 반대로 차단은 신고를 만들지 않는다. 마음에 안 드는 것과 규정 위반은 다른 일이다.

-- ─────────────────────────────────────────────────────────────────────────────
-- 차단
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE user_block_rls (
    id              BIGSERIAL    PRIMARY KEY,
    blocker_user_id BIGINT       NOT NULL REFERENCES user_mst (id) ON DELETE CASCADE,
    blocked_user_id BIGINT       NOT NULL REFERENCES user_mst (id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uk_user_block_rls   UNIQUE (blocker_user_id, blocked_user_id),
    CONSTRAINT ck_user_block_self  CHECK  (blocker_user_id <> blocked_user_id)
);

-- 피드·댓글을 그릴 때마다 "내가 차단한 사람" 전체를 한 번에 읽는다
CREATE INDEX idx_user_block_rls_blocker ON user_block_rls (blocker_user_id);
-- 댓글은 양방향으로 막으므로 "나를 차단한 사람" 도 역방향으로 찾아야 한다
CREATE INDEX idx_user_block_rls_blocked ON user_block_rls (blocked_user_id);

COMMENT ON TABLE user_block_rls IS
    '사용자 차단 (단방향 행). 글 노출은 차단한 쪽에서만 숨고, 댓글은 양방향으로 막는다';
COMMENT ON COLUMN user_block_rls.blocked_user_id IS
    '차단당한 사람. ⛔ 이 사실을 상대에게 알리지 말 것 — 알리는 순간 보복이 시작된다';

-- ─────────────────────────────────────────────────────────────────────────────
-- 신고
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE post_report_dtl (
    id               BIGSERIAL    PRIMARY KEY,
    reporter_user_id BIGINT       NOT NULL REFERENCES user_mst (id) ON DELETE CASCADE,
    target_type      VARCHAR(10)  NOT NULL,
    target_id        BIGINT       NOT NULL,
    target_user_id   BIGINT       NOT NULL REFERENCES user_mst (id) ON DELETE CASCADE,
    reason_cd        VARCHAR(20)  NOT NULL,
    detail           TEXT,
    status           VARCHAR(10)  NOT NULL DEFAULT 'PENDING',
    action_taken     VARCHAR(20),
    handled_by       BIGINT       REFERENCES user_mst (id) ON DELETE SET NULL,
    handled_at       TIMESTAMPTZ,
    handler_memo     TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uk_post_report_dtl UNIQUE (reporter_user_id, target_type, target_id),
    CONSTRAINT ck_post_report_target CHECK (
        target_type IN ('POST', 'COMMENT', 'USER')),
    CONSTRAINT ck_post_report_reason CHECK (
        reason_cd IN ('SPAM', 'ABUSE', 'SEXUAL', 'PRIVACY',
                      'ILLEGAL_TRADE', 'ANIMAL_CRUELTY', 'ETC')),
    CONSTRAINT ck_post_report_status CHECK (
        status IN ('PENDING', 'RESOLVED', 'REJECTED')),
    CONSTRAINT ck_post_report_action CHECK (
        action_taken IS NULL OR action_taken IN ('NONE', 'BLIND', 'DELETE', 'SUSPEND')),
    -- 처리한 신고에는 처리자와 시각이 반드시 남는다. 누가 언제 판단했는지가 곧 근거다
    CONSTRAINT ck_post_report_handled CHECK (
        (status = 'PENDING' AND handled_at IS NULL)
        OR (status <> 'PENDING' AND handled_at IS NOT NULL AND handled_by IS NOT NULL)),
    CONSTRAINT ck_post_report_self CHECK (reporter_user_id <> target_user_id)
);

-- 운영자 큐: 미처리 신고를 오래된 순으로 본다
CREATE INDEX idx_post_report_dtl_queue  ON post_report_dtl (status, created_at);
-- 같은 대상에 신고가 몇 건 쌓였는지 (누적 3건이면 운영자에게 알림)
CREATE INDEX idx_post_report_dtl_target ON post_report_dtl (target_type, target_id);

COMMENT ON TABLE post_report_dtl IS
    '커뮤니티 신고. 접수되면 신고자→작성자 차단도 함께 생성된다 (신고 취소는 없고 차단만 해제 가능)';
COMMENT ON COLUMN post_report_dtl.target_user_id IS
    '신고당한 글·댓글의 작성자. 대상 글이 지워져도 누구를 신고한 것인지는 남아야 해서 비정규화한다';
COMMENT ON COLUMN post_report_dtl.reason_cd IS
    'SPAM=도배·광고 / ABUSE=욕설·혐오 / SEXUAL=음란 / PRIVACY=개인정보 노출 / '
    'ILLEGAL_TRADE=불법 분양·판매 / ANIMAL_CRUELTY=동물 학대 / ETC=기타. '
    '뒤 두 개는 파충류 커뮤니티에서 실제로 가장 많이 나오는 신고라 일반 세트에 더한 것이다';
COMMENT ON COLUMN post_report_dtl.action_taken IS
    'NONE=위반 아님 / BLIND=가림 / DELETE=삭제 / SUSPEND=계정 정지. status<>PENDING 일 때만 채운다';

-- ─────────────────────────────────────────────────────────────────────────────
-- 블라인드 — 운영자가 가린 글·댓글
--
-- ⛔ deleted_at 과 절대 합치지 말 것. 삭제는 작성자가 한 일이고 블라인드는 운영자가 한 일이다.
--    분쟁이 나면 원문이 남아 있어야 하므로 내용은 지우지 않고 응답에서만 치환한다.
--    엔티티의 @SQLRestriction 은 deleted_at 만 보므로 블라인드 글은 조회 자체는 계속 된다.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE post_mst         ADD COLUMN IF NOT EXISTS blinded_at TIMESTAMPTZ;
ALTER TABLE post_mst         ADD COLUMN IF NOT EXISTS blinded_by BIGINT REFERENCES user_mst (id) ON DELETE SET NULL;
ALTER TABLE post_comment_dtl ADD COLUMN IF NOT EXISTS blinded_at TIMESTAMPTZ;
ALTER TABLE post_comment_dtl ADD COLUMN IF NOT EXISTS blinded_by BIGINT REFERENCES user_mst (id) ON DELETE SET NULL;

COMMENT ON COLUMN post_mst.blinded_at IS
    '운영자가 가린 시각. 내용은 그대로 두고 응답에서만 치환한다 (작성자 삭제는 deleted_at)';
COMMENT ON COLUMN post_comment_dtl.blinded_at IS
    '운영자가 가린 시각. 내용은 그대로 두고 응답에서만 치환한다 (작성자 삭제는 deleted_at)';
