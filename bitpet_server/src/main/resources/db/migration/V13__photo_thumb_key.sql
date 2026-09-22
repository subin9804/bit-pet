-- 사진 썸네일 키 (2026-09-22)
--
-- 목록·아바타에서 3MB 원본을 그대로 내려받던 것을 512px 축소본으로 바꾸기 위한 컬럼.
-- NULL 을 허용하는 이유는 **기존 사진을 백필하지 않기 때문**이다 — 썸네일은 앱이
-- 업로드 시점에 만들어 같이 PUT 하므로(업로드가 presigned PUT 이라 이미지 바이트가
-- 서버를 지나가지 않는다) 이미 올라간 사진과 구버전 앱이 올리는 사진에는 없다.
-- 앱은 `thumbnailUrl ?? url` 로 흡수한다.
ALTER TABLE photo_dtl ADD COLUMN thumb_s3_key VARCHAR(255);

COMMENT ON COLUMN photo_dtl.thumb_s3_key IS '썸네일 S3 키(짧은 변 512px 기준 JPEG). NULL = 썸네일 없음 → 원본으로 폴백';
