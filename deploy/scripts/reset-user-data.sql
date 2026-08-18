-- 사용자 데이터 전체 초기화 (개발용)
--
-- 실행:
--   docker exec -i bitpet-postgres psql -U bitpet -d bitpet -v ON_ERROR_STOP=1 < reset-user-data.sql
--
-- ⚠️ 코드/시드 테이블은 건드리지 않는다. 특히 species_cd·morph_cd 를 지우면 안 된다:
--    R__ (Repeatable) 마이그레이션은 "파일 체크섬이 바뀔 때만" 재실행되므로, 데이터만 지우면
--    서버를 재시작해도 Flyway 가 다시 심어주지 않는다. 빈 테이블로 남아 개체 등록이 불가능해진다.
--
-- ⛔ flyway_schema_history 도 절대 지우지 말 것. 지우면 Flyway 가 V1 부터 다시 적용하려다
--    이미 존재하는 테이블에 부딪혀 기동이 깨진다.

BEGIN;

-- TRUNCATE 는 FK 로 엮인 테이블을 한 문장에 함께 적어야 한다 (따로 지우면 참조 위반).
-- RESTART IDENTITY 로 시퀀스도 1부터 되돌린다 — 안 하면 새 개체 id 가 15번부터 시작한다.
TRUNCATE TABLE
    -- 사용자·인증
    user_mst,
    user_oauth_rls,
    device_token_rls,
    admin_role_rls,

    -- 개체
    pet_mst,
    pet_keeper_rls,
    pet_morph_rls,
    pet_relation_rls,
    pet_share_invitation,

    -- 사육 기록
    weight_dtl,
    feeding_dtl,
    cleaning_dtl,
    memo_dtl,
    memo_tag_rls,
    memo_vet_ext_dtl,
    mating_dtl,
    laying_dtl,
    laying_hatch_dtl,

    -- 루틴
    routine_mst,
    routine_pet_rls,
    routine_log_dtl,

    -- 사진 (S3 객체는 별도로 정리해야 한다 — 아래 주석 참고)
    photo_dtl,
    s3_delete_queue_dtl,

    -- 커뮤니티
    post_mst,
    post_comment_dtl,
    post_like_rls,
    post_photo_dtl,

    -- 알림
    notification_log_dtl,

    -- NFC 태그
    -- ⚠️ 운영에서는 절대 지우면 안 되는 테이블이다. 태그는 실물 재고이고 bind_hst 는
    --    소유권 분쟁 판정 근거(append-only)다. 로컬 개발 DB 라서 함께 비운다.
    nfc_tag_mst,
    nfc_tag_bind_hst,

    -- 일련번호 풀 사용량 통계. 개체가 전부 사라졌으므로 함께 되돌린다.
    serial_pool_stat_mst
RESTART IDENTITY CASCADE;

COMMIT;

-- 남은 것 확인 — 아래 값이 나와야 정상이다.
SELECT 'species_cd' AS t, count(*) AS cnt, '148 이어야 함' AS expect FROM species_cd
UNION ALL SELECT 'morph_cd',         count(*), '254 이어야 함' FROM morph_cd
UNION ALL SELECT 'memo_tag_cd',      count(*), '5 이어야 함'   FROM memo_tag_cd
UNION ALL SELECT 'post_category_cd', count(*), '4 이어야 함'   FROM post_category_cd
UNION ALL SELECT 'user_mst',         count(*), '0 이어야 함'   FROM user_mst
UNION ALL SELECT 'pet_mst',          count(*), '0 이어야 함'   FROM pet_mst
ORDER BY 1;

-- ─────────────────────────────────────────────────────────────
-- 이 스크립트가 하지 않는 것
--
-- 1) S3(LocalStack) 에 올라간 사진 파일은 남는다. DB 행만 지우므로 참조 없는 객체가 된다.
--    비우려면:  docker exec bitpet-localstack awslocal s3 rm s3://bitpet-dev --recursive
--
-- 2) 폰에 깔린 앱의 로컬 캐시(Drift, bitpet.sqlite)는 그대로다. 서버를 비운 뒤 앱을 켜면
--    지워진 개체가 남아 보일 수 있다. 앱 데이터를 함께 지울 것:
--       adb shell pm clear me.tailog.app
--
-- 3) Redis 의 리프레시 토큰은 남는다. 계정이 사라졌으므로 로그인 상태가 이상해질 수 있다.
--       docker exec bitpet-redis redis-cli FLUSHALL
-- ─────────────────────────────────────────────────────────────
