-- 알림 종류별 수신 설정 (B안).
--
-- 축은 notification_log_dtl.notification_type 과 같다. 별도 축을 만들면 알림 종류를
-- 추가할 때마다 두 곳을 맞춰야 하고, 어긋나면 "설정에는 있는데 안 꺼지는" 알림이 생긴다.
--
-- 유저당 1행 · 컬럼당 1종류. 종류별 행으로 두면 판정 한 번에 N행을 읽어야 하는데
-- 이건 알림을 보낼 때마다 도는 조회다.
--
-- ⚠️ 행이 없으면 '전부 켜짐'이다. 가입 시점에 만들지 않고 처음 끌 때 생긴다 —
--    없는 상태와 기본값 상태를 같게 두면 백필이 필요 없다.
--
-- 여기에 없는 두 가지:
--   SYSTEM(공지·점검) — 끌 수 없다. 점검 안내를 못 받으면 곤란한 쪽이 사용자다.
--   MARKETING         — user_agreement_dtl 이 관리한다. 마케팅 수신은 설정이 아니라
--                       법이 요구하는 동의 기록이고, 소스가 둘이면 반드시 어긋난다.

CREATE TABLE user_notification_pref (
    user_id     BIGINT       PRIMARY KEY REFERENCES user_mst (id) ON DELETE CASCADE,
    routine     BOOLEAN      NOT NULL DEFAULT true,
    comment     BOOLEAN      NOT NULL DEFAULT true,
    post_like   BOOLEAN      NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  user_notification_pref IS
    '알림 종류별 푸시 수신 설정. 행이 없으면 전부 켜짐';
COMMENT ON COLUMN user_notification_pref.routine IS
    'ROUTINE_ALARM — 급여·체중·청소 예정 알림';
COMMENT ON COLUMN user_notification_pref.comment IS
    'COMMUNITY_COMMENT — 내 글에 달린 댓글';
COMMENT ON COLUMN user_notification_pref.post_like IS
    'COMMUNITY_LIKE — 내 글을 좋아한 사람. like 는 SQL 예약어라 컬럼명을 피했다';


-- 설정으로 꺼둔 알림의 상태값. SENT 로 두면 발송 통계가 거짓이 되고, FAILED 로 두면
-- 장애 알람이 울린다. 안 보낸 것은 성공도 실패도 아니다.
ALTER TABLE notification_log_dtl DROP CONSTRAINT ck_notification_log_status;
ALTER TABLE notification_log_dtl ADD  CONSTRAINT ck_notification_log_status
    CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'READ', 'SKIPPED'));

COMMENT ON COLUMN notification_log_dtl.status IS
    'PENDING / SENT / FAILED / READ / SKIPPED(수신 설정으로 푸시 생략 — 알림함에는 노출)';
