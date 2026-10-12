-- V16__laying_note_dtl.sql
-- 유정란(클러치) 관리 — 날짜별 관찰 메모 + 알 번호.
--
-- 앱에 '알' 탭을 붙이면서 두 가지가 모자랐다.
--
-- 1) 날짜별 메모를 둘 곳이 없다.
--    laying_dtl.memo 는 클러치당 한 칸이라 "9.20 캔들링 / 10.9 핍 확인"처럼 날짜를 쌓을 수 없고,
--    laying_hatch_dtl.memo 는 알 단위라 "인큐 온도를 올렸다" 같은 클러치 전체 관찰과 맞지 않는다.
--    한 칸에 날짜를 글로 쌓으면 정렬·수정·삭제가 전부 문자열 편집이 되므로 테이블을 나눈다.
--
-- 2) 알에 번호가 없다.
--    화면은 알을 칸(그리드)으로 그리고 "3번 알"로 부르는데, laying_hatch_dtl 은
--    해칭이 생길 때만 행이 하나씩 붙는 구조라 "몇 번째 알"이 존재하지 않았다.
--    egg_index 를 주고, 산란 등록 시 egg_count_total 만큼 PENDING 행을 미리 만든다.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. 알 번호
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE laying_hatch_dtl ADD COLUMN egg_index integer;

COMMENT ON COLUMN laying_hatch_dtl.egg_index IS '클러치 안에서의 알 번호 (1부터) — 화면의 알 칸 순서';

-- 기존 행 번호 부여: 클러치별로 만들어진 순서대로 1..n
WITH numbered AS (
    SELECT id,
           row_number() OVER (PARTITION BY laying_id ORDER BY created_at, id) AS rn
      FROM laying_hatch_dtl
     WHERE deleted_at IS NULL
)
UPDATE laying_hatch_dtl h
   SET egg_index = n.rn
  FROM numbered n
 WHERE h.id = n.id;

-- 알 개수만큼 PENDING 행 채우기 — 이미 행이 있는 번호는 건드리지 않는다.
-- (해칭 기록이 알 개수보다 많은 비정상 데이터는 그대로 둔다 — 지우는 건 사용자 몫)
INSERT INTO laying_hatch_dtl (id, laying_id, status, egg_index, created_by_user_id)
SELECT nextval('laying_hatch_dtl_id_seq'), l.id, 'PENDING', g.i, l.created_by_user_id
  FROM laying_dtl l
  CROSS JOIN LATERAL generate_series(1, l.egg_count_total) AS g(i)
 WHERE l.deleted_at IS NULL
   AND NOT EXISTS (
        SELECT 1 FROM laying_hatch_dtl h
         WHERE h.laying_id = l.id AND h.deleted_at IS NULL AND h.egg_index = g.i
   );

-- 같은 클러치에 같은 번호의 알이 둘일 수는 없다. 소프트 삭제된 행은 제외.
CREATE UNIQUE INDEX uk_hatch_laying_egg_index
    ON laying_hatch_dtl (laying_id, egg_index)
 WHERE deleted_at IS NULL AND egg_index IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. 날짜별 관찰 메모
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE laying_note_dtl (
    id                 BIGSERIAL    PRIMARY KEY,
    laying_id          BIGINT       NOT NULL REFERENCES laying_dtl (id) ON DELETE CASCADE,
    noted_at           DATE         NOT NULL,
    content            TEXT         NOT NULL,
    created_by_user_id BIGINT,
    deleted_at         TIMESTAMPTZ,
    sync_version       BIGINT       NOT NULL DEFAULT 1,
    client_id          VARCHAR(64),
    client_change_id   UUID,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT chk_laying_note_content_not_blank CHECK (btrim(content) <> '')
);

COMMENT ON TABLE laying_note_dtl IS '클러치의 날짜별 관찰 메모 — laying_dtl 1:N';
COMMENT ON COLUMN laying_note_dtl.noted_at IS '관찰 날짜 (시각 아님) — 같은 날 여러 줄 허용';

-- 클러치 상세는 항상 "이 클러치의 메모를 최신순으로" 읽는다
CREATE INDEX idx_laying_note_laying_date
    ON laying_note_dtl (laying_id, noted_at DESC)
 WHERE deleted_at IS NULL;

CREATE TRIGGER trg_laying_note_dtl_sync_version
    BEFORE UPDATE ON laying_note_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();
