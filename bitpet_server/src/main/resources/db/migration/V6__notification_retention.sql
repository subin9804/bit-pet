-- 알림 로그 보존기간 정리를 위한 인덱스.
--
-- notification_log_dtl 은 지금까지 지워지는 경로가 하나도 없었다. 루틴 알람은 유저당
-- 하루 몇 건씩 쌓이므로 이 테이블만 단조 증가한다 (유저가 늘면 가장 큰 테이블이 된다).
-- NotificationRetentionScheduler 가 매일 오래된 행을 지우는데, 조건이 sent_at 단독이라
-- 기존 인덱스로는 못 탄다:
--   idx_notification_log_status     (status, sent_at)          — 선두가 status
--   idx_notification_log_user_time  (user_id, sent_at DESC)    — 선두가 user_id
--   idx_notification_log_type       (user_id, notification_type, sent_at DESC)
-- 인덱스가 없어도 동작은 하지만(전체 스캔) 행이 쌓일수록 매일 밤 테이블을 통째로 읽는다.
--
-- CONCURRENTLY 를 쓰지 않는 이유: Flyway 는 마이그레이션을 트랜잭션 안에서 돌리는데
-- CREATE INDEX CONCURRENTLY 는 트랜잭션 밖에서만 된다. 첫 배포 시점엔 행이 없어
-- 테이블 잠금 시간이 사실상 0이다. 운영에 데이터가 쌓인 뒤 인덱스를 더 만들 일이 생기면
-- 그때는 psql 로 CONCURRENTLY 를 직접 실행하고 마이그레이션은 IF NOT EXISTS 로 둘 것.
CREATE INDEX IF NOT EXISTS idx_notification_log_sent_at
    ON notification_log_dtl USING btree (sent_at);
