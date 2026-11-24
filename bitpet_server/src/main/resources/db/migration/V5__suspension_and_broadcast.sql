-- 커뮤니티 이용 정지 + 전체 푸시 발송 이력 (2026-11-24)
--
-- ① user_suspension_dtl — 신고 처리의 SUSPEND 조치가 남기는 정지 기록.
--    정지는 **커뮤니티만** 막는다(글·댓글·좋아요·사진·신고 쓰기). 내 개체 기록·루틴은 그대로다 —
--    사육 기록은 개인 데이터라 커뮤니티 위반으로 빼앗을 성질이 아니다 (사용자 결정).
--    user_mst 에 '정지 끝 시각' 컬럼 하나를 두지 않고 행으로 남기는 이유: 몇 번 정지됐는지,
--    누가 왜 풀었는지가 다음 판단의 근거다. 상태는 행에서 계산한다 —
--    released_at IS NULL AND (ends_at IS NULL OR ends_at > now()) 이면 정지 중. ends_at NULL = 영구.
--    기간이 지나면 저절로 풀린다(배치 없음).
--
-- ② push_broadcast_dtl — 운영자 전체 푸시 한 번 = 한 행. 받는 사람별 기록은 notification_log_dtl 에 쌓인다.
--    marketing_yn = 'Y' 면 마케팅 수신 동의자에게만, 제목 앞에 '(광고)' 를 붙여 보냈다는 뜻이다 (정보통신망법 제50조).
CREATE TABLE user_suspension_dtl (
    id           bigserial PRIMARY KEY,
    user_id      bigint       NOT NULL REFERENCES user_mst (id) ON DELETE CASCADE,
    report_id    bigint       REFERENCES post_report_dtl (id) ON DELETE SET NULL,
    reason       varchar(500),
    ends_at      timestamptz,
    created_by   bigint       NOT NULL,
    released_at  timestamptz,
    released_by  bigint,
    created_at   timestamptz  NOT NULL DEFAULT now(),
    updated_at   timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ck_user_suspension_released CHECK ((released_at IS NULL) = (released_by IS NULL))
);

CREATE INDEX idx_user_suspension_user ON user_suspension_dtl (user_id) WHERE released_at IS NULL;

COMMENT ON TABLE user_suspension_dtl IS '커뮤니티 이용 정지 — 신고 처리 SUSPEND 조치. 커뮤니티 쓰기만 막는다';
COMMENT ON COLUMN user_suspension_dtl.ends_at IS '정지 끝 시각. NULL = 영구. 지나면 저절로 풀린다';
COMMENT ON COLUMN user_suspension_dtl.released_at IS '운영자가 기간 전에 푼 시각. 기간 만료로 풀린 건 비어 있다';

CREATE TABLE push_broadcast_dtl (
    id            bigserial PRIMARY KEY,
    title         varchar(100) NOT NULL,
    body          varchar(500) NOT NULL,
    marketing_yn  varchar(1)   NOT NULL,
    target_count  integer      NOT NULL,
    created_by    bigint       NOT NULL,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ck_push_broadcast_marketing_yn CHECK (marketing_yn IN ('Y', 'N'))
);

COMMENT ON TABLE push_broadcast_dtl IS '운영자 전체 푸시 발송 이력 (/admin/push). 받는 사람별 기록은 notification_log_dtl';
COMMENT ON COLUMN push_broadcast_dtl.title IS '운영자가 입력한 제목 그대로 — 마케팅이면 실제 발송 제목엔 (광고) 가 붙는다';
COMMENT ON COLUMN push_broadcast_dtl.marketing_yn IS 'Y = 마케팅 수신 동의자에게만, 제목 앞 (광고)';
COMMENT ON COLUMN push_broadcast_dtl.target_count IS '발송 대상 수 (발송 시점 기준)';
