-- 홈 상단 배너 (2026-11-24)
--
-- 앱에 하드코딩돼 있던 배너를 서버로 옮긴다. 배너를 바꿀 때마다 스토어 심사를 기다릴 수 없어서다.
-- 운영자는 웹 관리 페이지(/admin/banners)에서 PC로 등록한다.
--
-- 링크는 셋 중 하나: NONE(눌리지 않음) / ROUTE(앱 내부 경로, '/' 로 시작) / URL(외부 https).
-- 자녀 계정(만 14세 미만)에는 URL 배너를 내리지 않는다 — 가족 정책상 아동에게 외부 링크를 띄우지 않는다.
-- 노출 기간은 둘 다 비우면 상시. 이미지는 S3 키(banners/...)를 저장한다.
CREATE TABLE home_banner_mst (
    id          bigserial PRIMARY KEY,
    title       varchar(40)  NOT NULL,
    body        varchar(60),
    badge       varchar(10),
    image_key   varchar(300),
    link_type   varchar(10)  DEFAULT 'NONE' NOT NULL,
    link_value  varchar(500),
    start_at    timestamptz,
    end_at      timestamptz,
    sort_order  integer      DEFAULT 0 NOT NULL,
    active_yn   varchar(1)   DEFAULT 'Y' NOT NULL,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ck_home_banner_mst_link_type CHECK (link_type IN ('NONE', 'ROUTE', 'URL')),
    CONSTRAINT ck_home_banner_mst_link_value CHECK ((link_type = 'NONE') = (link_value IS NULL)),
    CONSTRAINT ck_home_banner_mst_active_yn CHECK (active_yn IN ('Y', 'N')),
    CONSTRAINT ck_home_banner_mst_period CHECK (start_at IS NULL OR end_at IS NULL OR start_at < end_at)
);

COMMENT ON TABLE home_banner_mst IS '홈 상단 배너 — 웹 관리 페이지(/admin/banners)에서 등록';
COMMENT ON COLUMN home_banner_mst.link_type IS 'NONE 눌리지 않음 / ROUTE 앱 내부 경로 / URL 외부 링크(자녀 계정엔 안 보임)';
COMMENT ON COLUMN home_banner_mst.start_at IS '노출 시작. null 이면 즉시';
COMMENT ON COLUMN home_banner_mst.end_at IS '노출 끝(미포함). null 이면 무기한';
COMMENT ON COLUMN home_banner_mst.sort_order IS '작을수록 먼저';
