-- =============================================================================
-- V43: 기록 테이블에 created_by_user_id 추가
--   - 공유 개체에서 어느 사육자가 기록을 남겼는지 식별
--   - 백필: 기존 기록은 개체 소유자(pet_mst.user_id)가 남긴 것으로 간주
-- =============================================================================

ALTER TABLE weight_dtl        ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE feeding_dtl       ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE cleaning_dtl      ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE memo_dtl          ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE laying_dtl        ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE laying_hatch_dtl  ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE mating_dtl        ADD COLUMN created_by_user_id BIGINT NULL;
ALTER TABLE routine_log_dtl   ADD COLUMN created_by_user_id BIGINT NULL;

-- pet_id를 가진 테이블: 개체 소유자로 백필
UPDATE weight_dtl   x SET created_by_user_id = p.user_id FROM pet_mst p WHERE p.id = x.pet_id;
UPDATE feeding_dtl  x SET created_by_user_id = p.user_id FROM pet_mst p WHERE p.id = x.pet_id;
UPDATE cleaning_dtl x SET created_by_user_id = p.user_id FROM pet_mst p WHERE p.id = x.pet_id;
UPDATE memo_dtl     x SET created_by_user_id = p.user_id FROM pet_mst p WHERE p.id = x.pet_id;
UPDATE laying_dtl   x SET created_by_user_id = p.user_id FROM pet_mst p WHERE p.id = x.pet_id;
UPDATE routine_log_dtl x SET created_by_user_id = p.user_id FROM pet_mst p WHERE p.id = x.pet_id;

-- laying_hatch_dtl: 부모 산란(laying_dtl)의 개체 소유자로 백필
UPDATE laying_hatch_dtl h SET created_by_user_id = p.user_id
FROM laying_dtl l JOIN pet_mst p ON p.id = l.pet_id
WHERE l.id = h.laying_id;

-- mating_dtl: female/male 중 존재하는 쪽 개체의 소유자로 백필 (둘 다 외부면 NULL)
UPDATE mating_dtl m SET created_by_user_id = p.user_id
FROM pet_mst p WHERE p.id = COALESCE(m.female_pet_id, m.male_pet_id);
