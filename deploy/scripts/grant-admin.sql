-- 운영자 권한 부여 (최초 1회 부트스트랩)
--
-- 문제: 권한을 주는 API 자체가 SUPER_ADMIN 을 요구한다. 첫 운영자는 아무도 만들어줄 수
-- 없으므로 DB 에서 직접 넣는다. 두 번째부터는 앱/API 로 준다.
--
-- 실행 (서버에서):
--   cd ~/bit-pet/deploy
--   docker compose -f docker-compose.prod.yml --env-file .env.prod exec -T postgres \
--     psql -U bitpet -d bitpet -v email="'su9804@gmail.com'" -f - < scripts/grant-admin.sql
--
-- ⚠️ 그 이메일로 앱에서 회원가입을 먼저 마쳐야 한다. user_mst 에 행이 없으면
--    아무것도 안 넣고 조용히 끝난다 (아래 확인 쿼리가 0건으로 알려준다).

\set ON_ERROR_STOP on

-- SUPER_ADMIN 과 MODERATOR 는 상하관계가 아니다. SUPER_ADMIN 을 가졌다고 MODERATOR 권한이
-- 딸려오지 않으므로(AdminGuard 가 등급을 나열해 판정한다), 둘 다 필요하면 두 행을 넣는다.
-- UNIQUE 가 (user_id, role) 이라 재실행해도 중복이 안 생긴다.
INSERT INTO admin_role_rls (id, user_id, role, granted_by)
SELECT nextval('admin_role_rls_id_seq'), u.id, r.role, u.id
FROM user_mst u
CROSS JOIN (VALUES ('SUPER_ADMIN'), ('MODERATOR')) AS r(role)
WHERE u.email = :email
  AND u.deleted_at IS NULL
ON CONFLICT (user_id, role) DO NOTHING;

-- 결과 확인. 2건이 나와야 정상이다.
SELECT u.email, a.role, a.granted_at
FROM admin_role_rls a
JOIN user_mst u ON u.id = a.user_id
WHERE u.email = :email
ORDER BY a.role;
