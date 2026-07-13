-- 개체 폐사(이별) 처리: NULL = 생존, 값 있으면 폐사일
ALTER TABLE pet_mst ADD COLUMN deceased_at DATE;
