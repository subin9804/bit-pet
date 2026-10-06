-- 먹이를 적지 않고 완료한 급여 루틴의 기록 백필
--
-- 예전엔 RoutineService 의 FEEDING 분기가 먹이 항목 하나당 feeding_dtl 한 줄을 썼다.
-- 먹이를 안 적고 '완료'만 누르면 항목이 0개라 feeding_dtl 이 아예 생기지 않았고,
-- 기록 화면에서 보이지도 수정되지도 않았다.
--
-- 루틴과 기록은 별개다 — 루틴은 할 일을 챙기는 도구일 뿐이고,
-- 수행했다는 사실 자체가 기록이다. 그래서 과거분도 기록으로 되살린다.
--
-- food_type = '' 은 "뭘 줬는지 안 적음" 이고 거식(refused_yn='Y', food_type IS NULL)과 다르다.
-- CHECK ck_feeding_dtl_food_type_by_refused 는 NOT NULL 만 보므로 빈 문자열은 통과한다.
INSERT INTO feeding_dtl (pet_id, food_type, fed_at, refused_yn,
                         routine_id, routine_log_id, created_by_user_id,
                         created_at, updated_at)
SELECT l.pet_id, '', l.executed_at, 'N',
       l.routine_id, l.id, l.created_by_user_id,
       l.created_at, l.created_at
FROM routine_log_dtl l
JOIN routine_mst r ON r.id = l.routine_id
WHERE l.status = 'COMPLETED'
  AND l.deleted_at IS NULL
  AND r.routine_type = 'FEEDING'
  AND NOT EXISTS (
      SELECT 1 FROM feeding_dtl f
      WHERE f.routine_log_id = l.id
  );
