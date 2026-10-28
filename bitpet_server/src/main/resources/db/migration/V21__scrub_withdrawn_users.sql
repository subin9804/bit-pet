-- 이미 탈퇴한 계정의 개인정보를 지운다.
--
-- 지금까지 탈퇴는 deleted_at 만 찍었다 — 이메일·닉네임·비밀번호 해시가 그대로 남아
-- 처리방침("탈퇴하면 지체 없이 삭제")과 어긋났다. 이후 탈퇴는 UserMst.softDelete() 가
-- 같은 값을 넣는다. 여기 자리표시자 형식을 바꾸면 그쪽도 같이 바꿀 것.
--
-- guardian_user_id 는 남긴다 — 법정대리인 동의 기록을 따라가는 유일한 경로다.
UPDATE user_mst
   SET email             = 'deleted-' || id || '@deleted.invalid',
       name              = 'deleted-' || id,
       password_hash     = '',
       profile_image_url = NULL,
       birth_date        = NULL,
       share_code        = NULL
 WHERE deleted_at IS NOT NULL;

DELETE FROM device_token_rls d
 USING user_mst u
 WHERE d.user_id = u.id
   AND u.deleted_at IS NOT NULL;
