-- Apple 로그인 (iOS 심사 4.8 — 다른 소셜 로그인을 제공하면 Apple 로그인도 함께 제공해야 한다)
-- 제공자 CHECK 를 넓히기만 한다. 넓히는 방향이라 구버전 서버가 같은 DB 에 붙어 있어도 안전하다.
ALTER TABLE user_oauth_rls DROP CONSTRAINT ck_user_oauth_rls_provider;
ALTER TABLE user_oauth_rls ADD CONSTRAINT ck_user_oauth_rls_provider
    CHECK (provider IN ('GOOGLE', 'KAKAO', 'NAVER', 'APPLE'));

COMMENT ON COLUMN user_oauth_rls.provider IS 'GOOGLE / KAKAO / NAVER / APPLE';
