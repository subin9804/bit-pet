-- 프로필 색상 (V10)
--
-- 회원가입 1단계의 'PROFILE COLOR' 는 지금까지 앱 화면 안에서만 살아 있었다.
-- 고르고 가입해도 서버로 보내지지 않아 다시 로그인하면 기본색으로 돌아간다.
-- 사용자 입장에서는 "골랐는데 저장이 안 되는" 필드였으므로 여기서 실제로 저장한다.
--
-- 값은 팔레트 키(sage/peach/sky/lilac/butter/coral). 색상 코드(#RRGGBB)를 저장하지 않는 이유는
-- 테마가 바뀌면 같은 'peach' 라도 실제 색이 달라져야 하기 때문이다 — 의미를 저장하고
-- 색은 앱이 해석한다. 팔레트가 늘어나도 마이그레이션이 필요 없다.
--
-- CHECK 을 걸지 않는 것도 같은 이유다. 팔레트 추가가 곧 DB 배포가 되어버리면
-- 색 하나 늘리는 데 무중단 배포 순서를 고민하게 된다. 모르는 값은 앱이 기본색으로 떨어뜨린다.

ALTER TABLE user_mst ADD COLUMN IF NOT EXISTS profile_color VARCHAR(20) NOT NULL DEFAULT 'peach';

COMMENT ON COLUMN user_mst.profile_color IS '프로필 아바타 색 팔레트 키 (sage/peach/sky/lilac/butter/coral). 사진이 있으면 테두리 색으로 쓰인다';
