-- 자녀 계정 커뮤니티 이용 허용 (2026-11-10, Google Play 가족 정책)
--
-- 가족 정책은 아동이 자유 형식 콘텐츠를 주고받는 기능을 '성인이 켜고 끌 수 있게' 하라고 한다.
-- 보호자가 자녀마다 켠다. 기본은 꺼짐 — 보호자가 고르기 전에 아이가 남들과 글을 주고받으면 안 된다.
--
-- 성인 계정에는 의미가 없는 컬럼이다 (판정은 만 14세 미만일 때만 이 값을 본다).
-- 만 14세가 되면 값과 무관하게 일반 회원처럼 쓴다 — 지우지 않고 그대로 둔다.
ALTER TABLE user_mst ADD COLUMN community_enabled boolean DEFAULT false NOT NULL;

COMMENT ON COLUMN user_mst.community_enabled IS '자녀 계정 커뮤니티 이용 허용 (보호자가 켬). 만 14세 미만일 때만 판정에 쓰인다';
