-- 내 개체 목록 순서 — 사람마다 따로 (2026-10-19)
--
-- 순서는 pet_mst 가 아니라 pet_keeper_rls 에 둔다: 공유받은 사육자가 순서를 바꿔도
-- 소유자의 목록은 그대로여야 한다. 값이 작을수록 위. 새 개체는 그 사람의 최솟값 - 1 로 맨 위.
--
-- 기존 행은 지금 보이는 순서(등록 순 = pet_id 오름차순)로 채운다.
-- 이별(폐사) 개체를 맨 뒤로 보내는 건 순서값과 무관하게 조회 시점에 한다.

ALTER TABLE pet_keeper_rls
    ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

UPDATE pet_keeper_rls k
SET sort_order = s.rn
FROM (SELECT pet_id, user_id,
             ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY pet_id) AS rn
      FROM pet_keeper_rls) s
WHERE k.pet_id = s.pet_id
  AND k.user_id = s.user_id;
