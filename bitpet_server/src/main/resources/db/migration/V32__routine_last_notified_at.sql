-- routine_mst: 알림 중복 방지용 last_notified_at 컬럼 추가
-- next_due_at은 이제 날짜 기준(Seoul midnight)으로만 저장되고
-- 스케줄러는 next_due_at을 변경하지 않고 이 컬럼만 갱신한다.
ALTER TABLE routine_mst
    ADD COLUMN last_notified_at TIMESTAMP WITH TIME ZONE;
