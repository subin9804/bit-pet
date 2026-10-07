-- CUSTOM 루틴을 메모 없이 완료한 과거 로그의 memo_dtl 백필
--
-- "'완료' 라는 것 자체가 기록이다" (2026-10-07 사용자 확정).
-- 예전에는 메모가 있을 때만 memo_dtl 을 만들고, 메모 없는 완료는 읽는 쪽에서
-- "[루틴제목] 완료" 로 합성해 보여줬다. 그 합성은 기록의 날짜를 수정하면
-- 짝(logged_at = executed_at)이 끊겨 옛 날짜에 유령으로 남는 버그가 있었고,
-- 애초에 루틴 로그를 기록 화면에 보여주는 것 자체가 원칙 위반이라 전부 제거했다.
-- 그래서 그 완료들이 **기록으로 실체화**되어야 한다.
--
-- content = '' 는 "메모를 아직 안 적음" 이라는 사실 그대로의 상태다
-- (feeding_dtl.food_type = '' 와 같은 취급, V14 참고). content 에 CHECK 는 없고
-- NOT NULL 뿐이라 통과한다.
INSERT INTO memo_dtl (pet_id, content, logged_at,
                      routine_id, routine_log_id, created_by_user_id,
                      created_at, updated_at)
SELECT l.pet_id, '', l.executed_at,
       l.routine_id, l.id, l.created_by_user_id,
       l.created_at, l.created_at
FROM routine_log_dtl l
JOIN routine_mst r ON r.id = l.routine_id
WHERE l.status = 'COMPLETED'
  AND l.deleted_at IS NULL
  AND r.routine_type = 'CUSTOM'
  -- 이미 실체가 있는 완료는 건너뛴다.
  -- deleted_at 을 보지 않는 것은 의도적이다 — 사용자가 이미 지운 기록은 되살리지 않는다.
  AND NOT EXISTS (SELECT 1 FROM memo_dtl m WHERE m.routine_log_id = l.id)
  -- routine_log_id 가 없던 시절에 생긴 메모는 시각으로 짝을 찾는다 (일회성 백필이라 안전)
  AND NOT EXISTS (SELECT 1 FROM memo_dtl m
                  WHERE m.routine_log_id IS NULL
                    AND m.routine_id = l.routine_id
                    AND m.pet_id = l.pet_id
                    AND m.logged_at = l.executed_at);
