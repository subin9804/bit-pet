-- V28: private_yn CHAR(1) → VARCHAR(1) 타입 변경 (Hibernate 호환)
ALTER TABLE pet_mst
    ALTER COLUMN private_yn TYPE VARCHAR(1);
