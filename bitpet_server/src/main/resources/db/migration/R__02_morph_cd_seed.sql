-- R__02_morph_cd_seed.sql
-- 모프 마스터 데이터 — Notion「종별 모프 마스터 v1.3 (morph_cd)」 표 기준, 2026-09-15 동기화
-- R 파일: 체크섬 변경 시 Flyway가 자동 재실행
--
-- 구조:
--   ① 임시 테이블 tmp_morph_seed 에 (종 코드, 모프) 전체 목록을 적재
--   ② 종 코드 오타 가드 — species_cd 에 없는 코드가 있으면 마이그레이션 실패
--   ③ INSERT ON CONFLICT (species_id, name_ko) DO UPDATE → 중복 실행 가능
--   ④ 목록에 없는 공식 모프(전 종) 정리
--      a. 개체(pet_morph_rls)가 안 물고 있으면 DELETE
--      b. 물고 있으면 FK RESTRICT 라 못 지우므로 is_active = false
--      사용자 정의 모프(is_user_defined = true)는 건드리지 않는다.
--      ⚠️ 이 파일에 없는 공식 모프는 매 실행마다 지워진다 — 공식 모프 추가는 반드시 여기에.
--
-- DO UPDATE 가 is_user_defined = false / created_by = NULL 로 되돌리는 이유(V7):
--   사용자가 커스텀 모프로 먼저 만들어둔 이름이 나중에 공식 카탈로그에 추가되면
--   uq_morph_cd_species_name_ko 때문에 행이 하나뿐이라, 플래그를 그대로 두면
--   그 모프가 만든 사람에게만 보이고 나머지 유저에겐 영영 안 보이게 된다.
--
-- has_health_concern = TRUE 항목:
--   BALL_PYTHON   : 캐러멜알비노, 스파이더, 샴페인, 범블비, 슈퍼모하비스파이더
--   HOGNOSE_SNAKE : 핑크파스텔알비노(PPA)
--   BEARDED_DRAGON: 실크백
--   HAMSTER_SYRIAN: 다크그레이 / CHINCHILLA: 블랙벨벳, 화이트
--
-- Notion 문서와의 차이:
--   - 납테일 종 코드는 Notion 의 KNOB_TAIL_* 가 아니라 실제 species_cd 코드 KNOB_TAILED_* 를 쓴다.
--   - 크레스티드 '초초'는 오타가 아니라 신모프다 ('초코'와 다름). 고치지 말 것.
--   - 레오파드게코 트렉퍼알비노 → 트램퍼알비노 (옛 이름 행은 ④ 에서 삭제된다)
--   - 저빌 슈메(Schimmel)는 목록에서 제외
--   - 글자 깨짐만 교정: 노멘→노멀, 카라멘알비노→카라멜알비노, 아멘→아멜, 카라멘→카라멜,
--     멘라닉→멜라닉, 샤드파이어→샌드파이어,
--     옜로우→옐로우, 토토이쉬셀→토터스쉘, 중간띄→중간띠, 신나모난→시나몬, 하니→허니,
--     롭헤어→롱헤어, 앉고라→앙고라, 곱슐털→곱슬털, 닛맥/닛메그→넛맥/넛메그,
--     콜러포인트→컬러포인트, 벨밻→벨벳, 블루다이아모드→블루다이아몬드,
--     하이화이트 하이퍼썸리티→하이화이트 하이퀄리티
-- ─────────────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS tmp_morph_seed;
CREATE TEMP TABLE tmp_morph_seed (
    species_code       varchar(50)  NOT NULL,
    name_ko            varchar(100) NOT NULL,
    name_en            varchar(100),
    alias_list         varchar(300),
    has_health_concern boolean      NOT NULL,
    display_order      smallint     NOT NULL
);

INSERT INTO tmp_morph_seed (species_code, name_ko, name_en, alias_list, has_health_concern, display_order) VALUES
-- ═══════════════════════════════════════════════════════════════════════
--  CRESTED_GECKO  (35)
-- ═══════════════════════════════════════════════════════════════════════
('CRESTED_GECKO', '노말',                 'Normal',                 '와일드타입',             FALSE, 100),
('CRESTED_GECKO', '핀스트라이프',         'Pinstripe',              '핀',                     FALSE, 200),
('CRESTED_GECKO', '할리퀸',               'Harlequin',              '할리',                   FALSE, 300),
('CRESTED_GECKO', '브린들',               'Brindle',                NULL,                     FALSE, 400),
('CRESTED_GECKO', '달마시안',             'Dalmatian',              '달마',                   FALSE, 500),
('CRESTED_GECKO', '슈퍼달마시안',         'Super Dalmatian',        '슈퍼달마',               FALSE, 600),
('CRESTED_GECKO', '릴리화이트',           'Lily White',             '릴리',                   FALSE, 700),
('CRESTED_GECKO', '논릴리',               'Non-Lily',               NULL,                     FALSE, 800),
('CRESTED_GECKO', '카푸치노',             'Cappuccino',             '카푸',                   FALSE, 900),
('CRESTED_GECKO', '슈퍼카푸치노',         'Super Cappuccino',       '슈퍼카푸',               FALSE, 1000),
('CRESTED_GECKO', '프라푸치노',           'Frappuccino',            '프랖',                   FALSE, 1100),
('CRESTED_GECKO', '루왁',                 'Luwak',                  NULL,                     FALSE, 1200),
('CRESTED_GECKO', '엠티백',               'Empty Back',             'EB,리버스핀스트라이프',  FALSE, 1300),
('CRESTED_GECKO', '아잔틱',               'Axanthic',               NULL,                     FALSE, 1400),
('CRESTED_GECKO', '크림시클',             'Creamsicle',             NULL,                     FALSE, 1500),
('CRESTED_GECKO', '팬텀',                 'Phantom',                NULL,                     FALSE, 1600),
('CRESTED_GECKO', '트라이컬러',           'Tricolor',               NULL,                     FALSE, 1700),
('CRESTED_GECKO', '익스트림할리퀸',       'Extreme Harlequin',      '익할',                   FALSE, 1800),
('CRESTED_GECKO', '트라이익스트림할리퀸', 'Tri-Extreme Harlequin',  '트익할',                 FALSE, 1900),
('CRESTED_GECKO', '쿼드타입',             'Quad Type',              '쿼드',                   FALSE, 2000),
('CRESTED_GECKO', 'SPT',                  'SPT',                    NULL,                     FALSE, 2100),
('CRESTED_GECKO', '레드',                 'Red',                    NULL,                     FALSE, 2200),
('CRESTED_GECKO', '옐로우',               'Yellow',                 NULL,                     FALSE, 2300),
('CRESTED_GECKO', '오렌지',               'Orange',                 NULL,                     FALSE, 2400),
('CRESTED_GECKO', '탠저린',               'Tangerine',              NULL,                     FALSE, 2500),
('CRESTED_GECKO', '초초',                 'Choco',                  NULL,                     FALSE, 2600),
('CRESTED_GECKO', '차콜',                 'Charcoal',               NULL,                     FALSE, 2700),
('CRESTED_GECKO', '하이포',               'Hypo',                   '하이포멜라니스틱',       FALSE, 2800),
('CRESTED_GECKO', '슈퍼하이포',           'Super Hypo',             '슈하',                   FALSE, 2900),
('CRESTED_GECKO', '벅스킨',               'Buckskin',               NULL,                     FALSE, 3000),
('CRESTED_GECKO', '레드벅',               'Red Buck',               NULL,                     FALSE, 3100),
('CRESTED_GECKO', '다크벅',               'Dark Buck',              NULL,                     FALSE, 3200),
('CRESTED_GECKO', '세이블',               'Sable',                  NULL,                     FALSE, 3300),
('CRESTED_GECKO', '슈퍼세이블',           'Super Sable',            '슈세',                   FALSE, 3400),
('CRESTED_GECKO', '릴잔틱',               'Lilzanthic',             '릴잔',                   FALSE, 3500),

-- ═══════════════════════════════════════════════════════════════════════
--  LEOPARD_GECKO  (28)
-- ═══════════════════════════════════════════════════════════════════════
('LEOPARD_GECKO', '노멀',             'Normal',              '와일드타입',     FALSE, 100),
('LEOPARD_GECKO', '하이옐로우',       'High Yellow',         'HY',             FALSE, 200),
('LEOPARD_GECKO', '트램퍼알비노',     'Tremper Albino',      'TA,트램퍼',      FALSE, 300),
('LEOPARD_GECKO', '벨알비노',         'Bell Albino',         '벨',             FALSE, 400),
('LEOPARD_GECKO', '레인워터알비노',   'Rainwater Albino',    'RW,라스베가스',  FALSE, 500),
('LEOPARD_GECKO', '맥스노우',         'Mack Snow',           'MS',             FALSE, 600),
('LEOPARD_GECKO', '슈퍼스노우',       'Super Snow',          'SS,슈스',        FALSE, 700),
('LEOPARD_GECKO', '블리자드',         'Blizzard',            '블리',           FALSE, 800),
('LEOPARD_GECKO', '머피패턴리스',     'Murphy Patternless',  '머피',           FALSE, 900),
('LEOPARD_GECKO', '이클립스',         'Eclipse',             NULL,             FALSE, 1000),
('LEOPARD_GECKO', '마블아이',         'Marble Eye',          NULL,             FALSE, 1100),
('LEOPARD_GECKO', '스노우글로우',     'Snow Glow',           NULL,             FALSE, 1200),
('LEOPARD_GECKO', '디아블로블랑코',   'Diablo Blanco',       'DB',             FALSE, 1300),
('LEOPARD_GECKO', '랩터',             'RAPTOR',              NULL,             FALSE, 1400),
('LEOPARD_GECKO', '슈퍼맥스노우',     'Super Mack Snow',     '슈퍼맥',         FALSE, 1500),
('LEOPARD_GECKO', '캐롯테일',         'Carrot Tail',         'CT',             FALSE, 1600),
('LEOPARD_GECKO', '탠저린',           'Tangerine',           NULL,             FALSE, 1700),
('LEOPARD_GECKO', '슈퍼하이포',       'Super Hypo',          'SH',             FALSE, 1800),
('LEOPARD_GECKO', '베이비블리자드',   'Baby Blizzard',       NULL,             FALSE, 1900),
('LEOPARD_GECKO', '에니그마',         'Enigma',              '엔클립스',       FALSE, 2000),
('LEOPARD_GECKO', '블랙나이트',       'Black Night',         'BN,블랙펄',      FALSE, 2100),
('LEOPARD_GECKO', '갤럭시',           'Galaxy',              NULL,             FALSE, 2200),
('LEOPARD_GECKO', '자이언트',         'Giant',               NULL,             FALSE, 2300),
('LEOPARD_GECKO', '슈퍼자이언트',     'Super Giant',         'SG',             FALSE, 2400),
('LEOPARD_GECKO', '밴디트',           'Bandit',              NULL,             FALSE, 2500),
('LEOPARD_GECKO', '스트라이프',       'Stripe',              NULL,             FALSE, 2600),
('LEOPARD_GECKO', '리버스스트라이프', 'Reverse Stripe',      'RS',             FALSE, 2700),
('LEOPARD_GECKO', '레드스트라이프',   'Red Stripe',          NULL,             FALSE, 2800),

-- ═══════════════════════════════════════════════════════════════════════
--  PICTUS_GECKO / 펫테일게코  (12)
-- ═══════════════════════════════════════════════════════════════════════
('PICTUS_GECKO', '노멀',         'Normal',          '와일드타입', FALSE, 100),
('PICTUS_GECKO', '제로',         'Zero',            NULL,         FALSE, 200),
('PICTUS_GECKO', '슈퍼제로',     'Super Zero',      NULL,         FALSE, 300),
('PICTUS_GECKO', '스팅어',       'Stinger',         NULL,         FALSE, 400),
('PICTUS_GECKO', '화이트아웃',   'White Out',       NULL,         FALSE, 500),
('PICTUS_GECKO', '스트라이프',   'Stripe',          NULL,         FALSE, 600),
('PICTUS_GECKO', '아멜라닉',     'Amelanistic',     '아멜',       FALSE, 700),
('PICTUS_GECKO', '카라멜알비노', 'Caramel Albino',  NULL,         FALSE, 800),
('PICTUS_GECKO', '고스트',       'Ghost',           NULL,         FALSE, 900),
('PICTUS_GECKO', '오레오',       'Oreo',            NULL,         FALSE, 1000),
('PICTUS_GECKO', '패턴리스',     'Patternless',     NULL,         FALSE, 1100),
('PICTUS_GECKO', '줄루',         'Zulu',            NULL,         FALSE, 1200),

-- ═══════════════════════════════════════════════════════════════════════
--  LEACHIANUS_GT  (13)
-- ═══════════════════════════════════════════════════════════════════════
('LEACHIANUS_GT', '야테',         'Yate',         NULL,    FALSE, 100),
('LEACHIANUS_GT', '코기스',       'Mt. Koghis',   '코기스', FALSE, 200),
('LEACHIANUS_GT', '포인디미에',   'Poindimié',    '푸에브', FALSE, 300),
('LEACHIANUS_GT', '마운트더트',   'Mt. Dzumac',   '즈마크', FALSE, 400),
('LEACHIANUS_GT', '누메아',       'Nouméa',       NULL,    FALSE, 500),
('LEACHIANUS_GT', '페어크오쇼이', 'Farino',       NULL,    FALSE, 600),
('LEACHIANUS_GT', '픽시',         'Pixie',        NULL,    FALSE, 700),
('LEACHIANUS_GT', '다크',         'Dark Phase',   NULL,    FALSE, 800),
('LEACHIANUS_GT', '라이트',       'Light Phase',  NULL,    FALSE, 900),
('LEACHIANUS_GT', '패치리스',     'Patchless',    NULL,    FALSE, 1000),
('LEACHIANUS_GT', '고스트',       'Ghost',        NULL,    FALSE, 1100),
('LEACHIANUS_GT', '오레오',       'Oreo',         NULL,    FALSE, 1200),
('LEACHIANUS_GT', '하이컬러',     'High Color',   NULL,    FALSE, 1300),

-- ═══════════════════════════════════════════════════════════════════════
--  LEACHIANUS_ISLAND  (8)
-- ═══════════════════════════════════════════════════════════════════════
('LEACHIANUS_ISLAND', '누아나',       'Nuu Ana',       NULL,          FALSE, 100),
('LEACHIANUS_ISLAND', '누아미',       'Nuu Ami',       NULL,          FALSE, 200),
('LEACHIANUS_ISLAND', '모로',         'Moro',          NULL,          FALSE, 300),
('LEACHIANUS_ISLAND', '파인아일랜드', 'Île des Pins',  '파인섬,데시', FALSE, 400),
('LEACHIANUS_ISLAND', '카아',         'Caanawa',       NULL,          FALSE, 500),
('LEACHIANUS_ISLAND', '메네라',       'Menere',        NULL,          FALSE, 600),
('LEACHIANUS_ISLAND', '브로스',       'Brosse',        NULL,          FALSE, 700),
('LEACHIANUS_ISLAND', '바요네즈',     'Bayonnaise',    NULL,          FALSE, 800),

-- ═══════════════════════════════════════════════════════════════════════
--  BALL_PYTHON  (50: 단일 유전자 35 + 콤보 15)
-- ═══════════════════════════════════════════════════════════════════════
-- 단일 유전자
('BALL_PYTHON', '노멀',         'Normal',           '와일드타입',          FALSE, 100),
('BALL_PYTHON', '파스텔',       'Pastel',           NULL,                  FALSE, 200),
('BALL_PYTHON', '슈퍼파스텔',   'Super Pastel',     NULL,                  FALSE, 300),
('BALL_PYTHON', '파이볼드',     'Piebald',          '파이드',              FALSE, 400),
('BALL_PYTHON', '알비노',       'Albino',           'T- 알비노',           FALSE, 500),
('BALL_PYTHON', '라벤더알비노', 'Lavender Albino',  'LA',                  FALSE, 600),
('BALL_PYTHON', '캐러멜알비노', 'Caramel Albino',   NULL,                  TRUE,  700),
('BALL_PYTHON', '액산틱',       'Axanthic',         'VPI 아잔틱',          FALSE, 800),
('BALL_PYTHON', '모하비',       'Mojave',           '모하브,모하',         FALSE, 900),
('BALL_PYTHON', '스파이더',     'Spider',           NULL,                  TRUE,  1000),
('BALL_PYTHON', '핀스트라이프', 'Pinstripe',        '핀',                  FALSE, 1100),
('BALL_PYTHON', '클라운',       'Clown',            NULL,                  FALSE, 1200),
('BALL_PYTHON', '옐로우벨리',   'Yellow Belly',     'YB',                  FALSE, 1300),
('BALL_PYTHON', '스펙터',       'Specter',          '스페터',              FALSE, 1400),
('BALL_PYTHON', '시나몬',       'Cinnamon',         NULL,                  FALSE, 1500),
('BALL_PYTHON', '블랙파스텔',   'Black Pastel',     'BP',                  FALSE, 1600),
('BALL_PYTHON', '디스코',       'Disco',            NULL,                  FALSE, 1700),
('BALL_PYTHON', '엔치',         'Enchi',            NULL,                  FALSE, 1800),
('BALL_PYTHON', '파스타베',     'Pastave',          NULL,                  FALSE, 1900),
('BALL_PYTHON', '레오파드',     'Leopard',          NULL,                  FALSE, 2000),
('BALL_PYTHON', '레서',         'Lesser',           '레서플래티널',        FALSE, 2100),
('BALL_PYTHON', '버터',         'Butter',           '부틀러',              FALSE, 2200),
('BALL_PYTHON', '바나나',       'Banana',           '코랄글로우',          FALSE, 2300),
('BALL_PYTHON', '샴페인',       'Champagne',        NULL,                  TRUE,  2400),
('BALL_PYTHON', '와이트',       'Wight',            NULL,                  FALSE, 2500),
('BALL_PYTHON', '마호가니',     'Mahogany',         NULL,                  FALSE, 2600),
('BALL_PYTHON', '스케일리스',   'Scaleless',        '스코어레스',          FALSE, 2700),
('BALL_PYTHON', 'GHI',          'GHI',              '헷레드',              FALSE, 2800),
('BALL_PYTHON', '데저트고스트', 'Desert Ghost',     'DG',                  FALSE, 2900),
('BALL_PYTHON', '슈퍼모하비',   'Super Mojave',     '슈모하',              FALSE, 3000),
('BALL_PYTHON', '파이어',       'Fire',             NULL,                  FALSE, 3100),
('BALL_PYTHON', '슈퍼파이어',   'Super Fire',       'BEL,블랙아이드루시',  FALSE, 3200),
('BALL_PYTHON', '바닐라',       'Vanilla',          NULL,                  FALSE, 3300),
('BALL_PYTHON', '토피',         'Toffee',           '토피벨리',            FALSE, 3400),
('BALL_PYTHON', '초콜릿',       'Chocolate',        '초콜렛',              FALSE, 3500),
-- 유명 콤보
('BALL_PYTHON', '킬러비',             'Killer Bee',           'KB',          FALSE, 4000),
('BALL_PYTHON', '범블비',             'Bumble Bee',           NULL,          TRUE,  4100),
('BALL_PYTHON', '슈퍼블래스트',       'Super Blast',          NULL,          FALSE, 4200),
('BALL_PYTHON', '파이어플라이',       'Firefly',              NULL,          FALSE, 4300),
('BALL_PYTHON', '파스텔클라운',       'Pastel Clown',         NULL,          FALSE, 4400),
('BALL_PYTHON', '바나나파이드',       'Banana Pied',          NULL,          FALSE, 4500),
('BALL_PYTHON', '블레이드',           'Blade',                NULL,          FALSE, 4600),
('BALL_PYTHON', '레몬블래스트',       'Lemon Blast',          NULL,          FALSE, 4700),
('BALL_PYTHON', '캔디',               'Candy',                NULL,          FALSE, 4800),
('BALL_PYTHON', '토피콤보',           'Toffee Combo',         NULL,          FALSE, 4900),
('BALL_PYTHON', 'GHI모하비',          'GHI Mojave',           '골드차일드',  FALSE, 5000),
('BALL_PYTHON', '모하비파이드',       'Mojave Pied',          NULL,          FALSE, 5100),
('BALL_PYTHON', '파스텔모하비',       'Pastel Mojave',        NULL,          FALSE, 5200),
('BALL_PYTHON', '헷크림',             'Het Cream',            NULL,          FALSE, 5300),
('BALL_PYTHON', '슈퍼모하비스파이더', 'Super Mojave Spider',  NULL,          TRUE,  5400),

-- ═══════════════════════════════════════════════════════════════════════
--  CORN_SNAKE  (25)
-- ═══════════════════════════════════════════════════════════════════════
('CORN_SNAKE', '노멀',             'Normal',          '와일드타입',          FALSE, 100),
('CORN_SNAKE', '아멜라니스틱',     'Amelanistic',     '아멜,Amel,레드알비노', FALSE, 200),
('CORN_SNAKE', '에너리스리스틱',   'Anerythristic',   '아네리,Anery',        FALSE, 300),
('CORN_SNAKE', '스노우',           'Snow',            '화이트',              FALSE, 400),
('CORN_SNAKE', '블리자드',         'Blizzard',        NULL,                  FALSE, 500),
('CORN_SNAKE', '캐러멜',           'Caramel',         NULL,                  FALSE, 600),
('CORN_SNAKE', '라벤더',           'Lavender',        NULL,                  FALSE, 700),
('CORN_SNAKE', '하이포멜라니스틱', 'Hypomelanistic',  '하이포,Hypo',         FALSE, 800),
('CORN_SNAKE', '고스트',           'Ghost',           '그리프',              FALSE, 900),
('CORN_SNAKE', '차콜',             'Charcoal',        NULL,                  FALSE, 1000),
('CORN_SNAKE', '모틀리',           'Motley',          '모토니컴러',          FALSE, 1100),
('CORN_SNAKE', '스트라이프',       'Striped',         '스트라이프드',        FALSE, 1200),
('CORN_SNAKE', '다이아몬드',       'Diamond',         NULL,                  FALSE, 1300),
('CORN_SNAKE', '블러드레드',       'Bloodred',        '블러드',              FALSE, 1400),
('CORN_SNAKE', '마이애미',         'Miami',           NULL,                  FALSE, 1500),
('CORN_SNAKE', '오키티',           'Okeetee',         NULL,                  FALSE, 1600),
('CORN_SNAKE', '키스트',           'Kisatchie',       '카스트',              FALSE, 1700),
('CORN_SNAKE', '버터',             'Butter',          NULL,                  FALSE, 1800),
('CORN_SNAKE', '그라나이트',       'Granite',         '옐로우러터',          FALSE, 1900),
('CORN_SNAKE', '캐러멜모틀리',     'Caramel Motley',  NULL,                  FALSE, 2000),
('CORN_SNAKE', '라이콘',           'Lycan',           NULL,                  FALSE, 2100),
('CORN_SNAKE', '신더',             'Cinder',          '신크리코',            FALSE, 2200),
('CORN_SNAKE', '딜루트',           'Dilute',          '디럭스',              FALSE, 2300),
('CORN_SNAKE', '스케일리스',       'Scaleless',       '스칼레스',            FALSE, 2400),
('CORN_SNAKE', '팔메토',           'Palmetto',        '팔름드',              FALSE, 2500),

-- ═══════════════════════════════════════════════════════════════════════
--  CALIFORNIA_KINGSNAKE  (15)
-- ═══════════════════════════════════════════════════════════════════════
('CALIFORNIA_KINGSNAKE', '노멀',             'Normal',          '와일드타입,블랙앤화이트', FALSE, 100),
('CALIFORNIA_KINGSNAKE', '알비노',           'Albino',          '아멜라니스틱',           FALSE, 200),
('CALIFORNIA_KINGSNAKE', '라벤더',           'Lavender',        NULL,                     FALSE, 300),
('CALIFORNIA_KINGSNAKE', '초콜릿',           'Chocolate',       NULL,                     FALSE, 400),
('CALIFORNIA_KINGSNAKE', '하이포멜라니스틱', 'Hypomelanistic',  '하이포',                 FALSE, 500),
('CALIFORNIA_KINGSNAKE', '스노우',           'Snow',            NULL,                     FALSE, 600),
('CALIFORNIA_KINGSNAKE', '고스트',           'Ghost',           NULL,                     FALSE, 700),
('CALIFORNIA_KINGSNAKE', '바나나',           'Banana',          NULL,                     FALSE, 800),
('CALIFORNIA_KINGSNAKE', '데저트',           'Desert Phase',    NULL,                     FALSE, 900),
('CALIFORNIA_KINGSNAKE', '스트라이프',       'Striped',         '스트라이프드',           FALSE, 1000),
('CALIFORNIA_KINGSNAKE', '하이화이트',       'High White',      '디바이딩스트라이프',     FALSE, 1100),
('CALIFORNIA_KINGSNAKE', '아베란트',         'Aberrant',        '어베란트',               FALSE, 1200),
('CALIFORNIA_KINGSNAKE', '블리자드',         'Blizzard',        NULL,                     FALSE, 1300),
('CALIFORNIA_KINGSNAKE', '카리키니아',       'Mexican Black',   NULL,                     FALSE, 1400),
('CALIFORNIA_KINGSNAKE', '패턴리스',         'Patternless',     NULL,                     FALSE, 1500),

-- ═══════════════════════════════════════════════════════════════════════
--  HOGNOSE_SNAKE  (20)
-- ═══════════════════════════════════════════════════════════════════════
('HOGNOSE_SNAKE', '노멀',             'Normal',              '와일드타입,클래식', FALSE, 100),
('HOGNOSE_SNAKE', '알비노',           'Albino',              'T- 알비노',         FALSE, 200),
('HOGNOSE_SNAKE', '콘다',             'Anaconda',            '아나콘다,Conda',    FALSE, 300),
('HOGNOSE_SNAKE', '슈퍼콘다',         'Superconda',          '슈퍼아나콘다',      FALSE, 400),
('HOGNOSE_SNAKE', '아크틱',           'Arctic',              'JMG아잔틱',         FALSE, 500),
('HOGNOSE_SNAKE', '슈퍼아크틱',       'Superarctic',         NULL,                FALSE, 600),
('HOGNOSE_SNAKE', '아잔틱',           'Axanthic',            NULL,                FALSE, 700),
('HOGNOSE_SNAKE', '카라멜',           'Caramel',             NULL,                FALSE, 800),
('HOGNOSE_SNAKE', '시나몬',           'Cinnamon',            NULL,                FALSE, 900),
('HOGNOSE_SNAKE', '라벤더',           'Lavender',            NULL,                FALSE, 1000),
('HOGNOSE_SNAKE', '루시스틱',         'Leucistic',           NULL,                FALSE, 1100),
('HOGNOSE_SNAKE', '핑크파스텔알비노', 'Pink Pastel Albino',  'PPA',               TRUE,  1200),
('HOGNOSE_SNAKE', '피스타치오',       'Pistachio',           NULL,                FALSE, 1300),
('HOGNOSE_SNAKE', '세이블',           'Sable',               NULL,                FALSE, 1400),
('HOGNOSE_SNAKE', '스위스초콜릿',     'Swiss Chocolate',     NULL,                FALSE, 1500),
('HOGNOSE_SNAKE', '토피벨리',         'Toffeebelly',         '토피',              FALSE, 1600),
('HOGNOSE_SNAKE', '익스트림레드',     'Extreme Red',         NULL,                FALSE, 1700),
('HOGNOSE_SNAKE', '에반스하이포',     'Evan''s Hypo',        NULL,                FALSE, 1800),
('HOGNOSE_SNAKE', '마이타이',         'Mai Tai',             NULL,                FALSE, 1900),
('HOGNOSE_SNAKE', '알비노아나콘다',   'Albino Anaconda',     NULL,                FALSE, 2000),

-- ═══════════════════════════════════════════════════════════════════════
--  BEARDED_DRAGON  (30)  1000번대=유전자, 2000번대=컬러, 3000번대=스케일, 4000번대=콤보
-- ═══════════════════════════════════════════════════════════════════════
('BEARDED_DRAGON', '노멀',               'Normal',                '와일드타입',       FALSE, 100),
('BEARDED_DRAGON', '하이포',             'Hypo',                  '하이포멜라니스틱', FALSE, 1000),
('BEARDED_DRAGON', '슈퍼하이포',         'Super Hypo',            'SH',               FALSE, 1100),
('BEARDED_DRAGON', '트랜스',             'Trans',                 '트랜스루센트',     FALSE, 1200),
('BEARDED_DRAGON', '슈퍼트랜스',         'Super Trans',           NULL,               FALSE, 1300),
('BEARDED_DRAGON', '헷하이포트랜스',     'Het Hypo Trans',        '헷하이포',         FALSE, 1400),
('BEARDED_DRAGON', '위트블리츠',         'Witblits',              '윗블리츠',         FALSE, 1500),
('BEARDED_DRAGON', '제로',               'Zero',                  NULL,               FALSE, 1600),
('BEARDED_DRAGON', '슈퍼제로',           'Super Zero',            NULL,               FALSE, 1700),
('BEARDED_DRAGON', '헷제로',             'Het Zero',              NULL,               FALSE, 1800),
('BEARDED_DRAGON', '더너',               'Dunner',                '다나에',           FALSE, 1900),
('BEARDED_DRAGON', '시트러스',           'Citrus',                '시트라스',         FALSE, 2000),
('BEARDED_DRAGON', '레드',               'Red',                   '블러드레드',       FALSE, 2100),
('BEARDED_DRAGON', '옐로우',             'Yellow',                NULL,               FALSE, 2200),
('BEARDED_DRAGON', '오렌지',             'Orange',                NULL,               FALSE, 2300),
('BEARDED_DRAGON', '샌드파이어',         'Sandfire',              NULL,               FALSE, 2400),
('BEARDED_DRAGON', '선버스트',           'Sunburst',              NULL,               FALSE, 2500),
('BEARDED_DRAGON', '화이트',             'White',                 NULL,               FALSE, 2600),
('BEARDED_DRAGON', '파스텔',             'Pastel',                NULL,               FALSE, 2700),
('BEARDED_DRAGON', '타이거',             'Tiger',                 NULL,               FALSE, 2800),
('BEARDED_DRAGON', '제너틱스트라이프',   'Genetic Stripe',        '진스트라이프',     FALSE, 2900),
('BEARDED_DRAGON', '레더백',             'Leatherback',           '레더',             FALSE, 3000),
('BEARDED_DRAGON', '슈퍼레더백',         'Super Leatherback',     '슈레더',           FALSE, 3100),
('BEARDED_DRAGON', '실크백',             'Silkback',              '실크,스케일리스',  TRUE,  3200),
('BEARDED_DRAGON', '마이크로스케일',     'Microscale',            NULL,               FALSE, 3300),
('BEARDED_DRAGON', '위트블리츠레더백',   'Witblits Leatherback',  NULL,               FALSE, 4000),
('BEARDED_DRAGON', '제로레더백',         'Zero Leatherback',      NULL,               FALSE, 4100),
('BEARDED_DRAGON', '헷제로위트블리츠',   'Het Zero Witblits',     NULL,               FALSE, 4200),
('BEARDED_DRAGON', '더너제로',           'Dunner Zero',           NULL,               FALSE, 4300),
('BEARDED_DRAGON', '슈퍼시트러스타이거', 'Super Citrus Tiger',    NULL,               FALSE, 4400),

-- ═══════════════════════════════════════════════════════════════════════
--  BLUE_TONGUE_SKINK  (25)  1000번대=로컬리티(아종), 2000번대=컬러 모프
-- ═══════════════════════════════════════════════════════════════════════
('BLUE_TONGUE_SKINK', '노던',           'Northern',     '노던블루텅',       FALSE, 1000),
('BLUE_TONGUE_SKINK', '이스턴',         'Eastern',      '이스턴블루텅',     FALSE, 1100),
('BLUE_TONGUE_SKINK', '웨스턴',         'Western',      '웨스턴블루텅',     FALSE, 1200),
('BLUE_TONGUE_SKINK', '센트랄리안',     'Centralian',   '센트럴',           FALSE, 1300),
('BLUE_TONGUE_SKINK', '타니말바',       'Tanimbar',     '타니',             FALSE, 1400),
('BLUE_TONGUE_SKINK', '메라우케',       'Merauke',      '메라',             FALSE, 1500),
('BLUE_TONGUE_SKINK', '할마헤라',       'Halmahera',    '할마',             FALSE, 1600),
('BLUE_TONGUE_SKINK', '이리안자야',     'Irian Jaya',   'IJ,이리안',        FALSE, 1700),
('BLUE_TONGUE_SKINK', '키',             'Kei Island',   '케이아일랜드',     FALSE, 1800),
('BLUE_TONGUE_SKINK', '인도네시안',     'Indonesian',   NULL,               FALSE, 1900),
('BLUE_TONGUE_SKINK', '알비노',         'Albino',       'T- 알비노',        FALSE, 2000),
('BLUE_TONGUE_SKINK', '하이포',         'Hypo',         '하이포멜라니스틱', FALSE, 2100),
('BLUE_TONGUE_SKINK', '슈퍼하이포',     'Super Hypo',   NULL,               FALSE, 2200),
('BLUE_TONGUE_SKINK', '카라멜',         'Caramel',      '캐러멜',           FALSE, 2300),
('BLUE_TONGUE_SKINK', '아잔틱',         'Axanthic',     NULL,               FALSE, 2400),
('BLUE_TONGUE_SKINK', 'T플러스알비노',  'T+ Albino',    'T+',               FALSE, 2500),
('BLUE_TONGUE_SKINK', '헷알비노',       'Het Albino',   NULL,               FALSE, 2600),
('BLUE_TONGUE_SKINK', '아네리스리스틱', 'Anerythristic','아네리',           FALSE, 2700),
('BLUE_TONGUE_SKINK', '스노우',         'Snow',         NULL,               FALSE, 2800),
('BLUE_TONGUE_SKINK', '핑크',           'Pink',         NULL,               FALSE, 2900),
('BLUE_TONGUE_SKINK', '플레임',         'Flame',        NULL,               FALSE, 3000),
('BLUE_TONGUE_SKINK', '시트러스',       'Citrus',       NULL,               FALSE, 3100),
('BLUE_TONGUE_SKINK', '실버',           'Silver',       NULL,               FALSE, 3200),
('BLUE_TONGUE_SKINK', '멜라니스틱',     'Melanistic',   '멜라닉',           FALSE, 3300),
('BLUE_TONGUE_SKINK', '패턴리스',       'Patternless',  NULL,               FALSE, 3400),

-- ═══════════════════════════════════════════════════════════════════════
--  ARGENTINE_BLACK_WHITE_TEGU  (12)
-- ═══════════════════════════════════════════════════════════════════════
('ARGENTINE_BLACK_WHITE_TEGU', '노멀',       'Normal',      '와일드타입',       FALSE, 100),
('ARGENTINE_BLACK_WHITE_TEGU', '알비노',     'Albino',      'T- 알비노',        FALSE, 200),
('ARGENTINE_BLACK_WHITE_TEGU', '차코안',     'Chacoan',     '차코',             FALSE, 300),
('ARGENTINE_BLACK_WHITE_TEGU', '블루',       'Blue',        '블루테구',         FALSE, 400),
('ARGENTINE_BLACK_WHITE_TEGU', '하이포',     'Hypo',        '하이포멜라니스틱', FALSE, 500),
('ARGENTINE_BLACK_WHITE_TEGU', '화이트',     'White',       '화이트테구',       FALSE, 600),
('ARGENTINE_BLACK_WHITE_TEGU', '블랙',       'Black',       '블랙테구',         FALSE, 700),
('ARGENTINE_BLACK_WHITE_TEGU', '핑크',       'Pink',        NULL,               FALSE, 800),
('ARGENTINE_BLACK_WHITE_TEGU', '헷알비노',   'Het Albino',  NULL,               FALSE, 900),
('ARGENTINE_BLACK_WHITE_TEGU', '슈퍼블루',   'Super Blue',  NULL,               FALSE, 1000),
('ARGENTINE_BLACK_WHITE_TEGU', '아잔틱',     'Axanthic',    NULL,               FALSE, 1100),
('ARGENTINE_BLACK_WHITE_TEGU', '멜라니스틱', 'Melanistic',  NULL,               FALSE, 1200),

-- ═══════════════════════════════════════════════════════════════════════
--  RED_TEGU  (8)
-- ═══════════════════════════════════════════════════════════════════════
('RED_TEGU', '노멀',     'Normal',      '와일드타입',   FALSE, 100),
('RED_TEGU', '하이레드', 'High Red',    '익스트림레드', FALSE, 200),
('RED_TEGU', '슈퍼레드', 'Super Red',   NULL,           FALSE, 300),
('RED_TEGU', '체리헤드', 'Cherry Head', NULL,           FALSE, 400),
('RED_TEGU', '알비노',   'Albino',      'T- 알비노',    FALSE, 500),
('RED_TEGU', '헷알비노', 'Het Albino',  NULL,           FALSE, 600),
('RED_TEGU', '하이포',   'Hypo',        NULL,           FALSE, 700),
('RED_TEGU', '파스텔',   'Pastel',      NULL,           FALSE, 800),

-- ═══════════════════════════════════════════════════════════════════════
--  KNOB_TAILED_PILBARENSIS  (12)  알비노 + 패턴리스 열성 유전자 확립
-- ═══════════════════════════════════════════════════════════════════════
('KNOB_TAILED_PILBARENSIS', '노멀',           'Normal',              '와일드타입',           FALSE, 100),
('KNOB_TAILED_PILBARENSIS', '알비노',         'Albino',              NULL,                   FALSE, 200),
('KNOB_TAILED_PILBARENSIS', '패턴리스',       'Patternless',         'PL',                   FALSE, 300),
('KNOB_TAILED_PILBARENSIS', '알비노패턴리스', 'Albino Patternless',  '더블비주얼',           FALSE, 400),
('KNOB_TAILED_PILBARENSIS', '헷알비노',       'Het Albino',          NULL,                   FALSE, 500),
('KNOB_TAILED_PILBARENSIS', '헷패턴리스',     'Het Patternless',     NULL,                   FALSE, 600),
('KNOB_TAILED_PILBARENSIS', '더블헷',         'Double Het',          '더블헷알비노패턴리스', FALSE, 700),
('KNOB_TAILED_PILBARENSIS', '하이옐로우',     'High Yellow',         NULL,                   FALSE, 800),
('KNOB_TAILED_PILBARENSIS', '하이오렌지',     'High Orange',         NULL,                   FALSE, 900),
('KNOB_TAILED_PILBARENSIS', '라이트',         'Light Phase',         NULL,                   FALSE, 1000),
('KNOB_TAILED_PILBARENSIS', '다크',           'Dark Phase',          NULL,                   FALSE, 1100),
('KNOB_TAILED_PILBARENSIS', '스트라이프',     'Striped',             NULL,                   FALSE, 1200),

-- ═══════════════════════════════════════════════════════════════════════
--  KNOB_TAILED_LEVIS  (7)
-- ═══════════════════════════════════════════════════════════════════════
('KNOB_TAILED_LEVIS', '노멀',       'Normal',       '와일드타입', FALSE, 100),
('KNOB_TAILED_LEVIS', '알비노',     'Albino',       NULL,         FALSE, 200),
('KNOB_TAILED_LEVIS', '패턴리스',   'Patternless',  NULL,         FALSE, 300),
('KNOB_TAILED_LEVIS', '헷알비노',   'Het Albino',   NULL,         FALSE, 400),
('KNOB_TAILED_LEVIS', '하이옐로우', 'High Yellow',  NULL,         FALSE, 500),
('KNOB_TAILED_LEVIS', '하이오렌지', 'High Orange',  NULL,         FALSE, 600),
('KNOB_TAILED_LEVIS', '라이트',     'Light Phase',  NULL,         FALSE, 700),

-- ═══════════════════════════════════════════════════════════════════════
--  KNOB_TAILED_WHEELERI  (8)
-- ═══════════════════════════════════════════════════════════════════════
('KNOB_TAILED_WHEELERI', '노멀',           'Normal',            '와일드타입', FALSE, 100),
('KNOB_TAILED_WHEELERI', '하이레드',       'High Red',          '하이오렌지', FALSE, 200),
('KNOB_TAILED_WHEELERI', '하이콘트라스트', 'High Contrast',     'HC',         FALSE, 300),
('KNOB_TAILED_WHEELERI', '볼드밴드',       'Bold Band',         NULL,         FALSE, 400),
('KNOB_TAILED_WHEELERI', '애버런트',       'Aberrant',          '불규칙밴딩', FALSE, 500),
('KNOB_TAILED_WHEELERI', '패턴리스핑크',   'Patternless Pink',  NULL,         FALSE, 600),
('KNOB_TAILED_WHEELERI', '라이트',         'Light Phase',       NULL,         FALSE, 700),
('KNOB_TAILED_WHEELERI', '다크',           'Dark Phase',        NULL,         FALSE, 800),

-- ═══════════════════════════════════════════════════════════════════════
--  KNOB_TAILED_CINCTUS  (7)
-- ═══════════════════════════════════════════════════════════════════════
('KNOB_TAILED_CINCTUS', '노멀',           'Normal',         '와일드타입', FALSE, 100),
('KNOB_TAILED_CINCTUS', '하이레드',       'High Red',       NULL,         FALSE, 200),
('KNOB_TAILED_CINCTUS', '하이콘트라스트', 'High Contrast',  'HC',         FALSE, 300),
('KNOB_TAILED_CINCTUS', '볼드밴드',       'Bold Band',      NULL,         FALSE, 400),
('KNOB_TAILED_CINCTUS', '애버런트',       'Aberrant',       '불규칙밴딩', FALSE, 500),
('KNOB_TAILED_CINCTUS', '라이트',         'Light Phase',    NULL,         FALSE, 600),
('KNOB_TAILED_CINCTUS', '다크',           'Dark Phase',     NULL,         FALSE, 700),

-- ═══════════════════════════════════════════════════════════════════════
--  KNOB_TAILED_AMYAE  (6)
-- ═══════════════════════════════════════════════════════════════════════
('KNOB_TAILED_AMYAE', '노멀',       'Normal',       '와일드타입', FALSE, 100),
('KNOB_TAILED_AMYAE', '하이옐로우', 'High Yellow',  NULL,         FALSE, 200),
('KNOB_TAILED_AMYAE', '하이오렌지', 'High Orange',  NULL,         FALSE, 300),
('KNOB_TAILED_AMYAE', '라이트',     'Light Phase',  NULL,         FALSE, 400),
('KNOB_TAILED_AMYAE', '다크',       'Dark Phase',   NULL,         FALSE, 500),
('KNOB_TAILED_AMYAE', '레드',       'Red',          NULL,         FALSE, 600),

-- ═══════════════════════════════════════════════════════════════════════
--  KNOB_TAILED_ASPER  (5)
-- ═══════════════════════════════════════════════════════════════════════
('KNOB_TAILED_ASPER', '노멀',       'Normal',       '와일드타입', FALSE, 100),
('KNOB_TAILED_ASPER', '하이옐로우', 'High Yellow',  NULL,         FALSE, 200),
('KNOB_TAILED_ASPER', '하이오렌지', 'High Orange',  NULL,         FALSE, 300),
('KNOB_TAILED_ASPER', '라이트',     'Light Phase',  NULL,         FALSE, 400),
('KNOB_TAILED_ASPER', '다크',       'Dark Phase',   NULL,         FALSE, 500),

-- ═══════════════════════════════════════════════════════════════════════
--  AFRICAN_PYGMY_DORMOUSE / 아프리카 겨울잠쥐  (15)
-- ═══════════════════════════════════════════════════════════════════════
('AFRICAN_PYGMY_DORMOUSE', '노멀',                 'Normal',                     '와일드타입',   FALSE, 100),
('AFRICAN_PYGMY_DORMOUSE', '링테일',               'Ring Tail',                  '링테일드',     FALSE, 200),
('AFRICAN_PYGMY_DORMOUSE', '파이드',               'Pied',                       '파이도',       FALSE, 300),
('AFRICAN_PYGMY_DORMOUSE', '오레오',               'Oreo',                       NULL,           FALSE, 400),
('AFRICAN_PYGMY_DORMOUSE', '오레오 하이퀄리티',    'Oreo High Quality',          'Oreo HQ',      FALSE, 500),
('AFRICAN_PYGMY_DORMOUSE', '화이트페이스',         'White Face',                 'WF',           FALSE, 600),
('AFRICAN_PYGMY_DORMOUSE', '더스트',               'Dust',                       NULL,           FALSE, 700),
('AFRICAN_PYGMY_DORMOUSE', '달마시안',             'Dalmatian',                  '달마',         FALSE, 800),
('AFRICAN_PYGMY_DORMOUSE', '하이화이트',           'High White',                 'HW',           FALSE, 900),
('AFRICAN_PYGMY_DORMOUSE', '하이화이트 하이퀄리티','High White High Quality',    'HW HQ',        FALSE, 1000),
('AFRICAN_PYGMY_DORMOUSE', '루시스틱',             'Leucistic',                  '루시스틱화이트',FALSE, 1100),
('AFRICAN_PYGMY_DORMOUSE', '슈퍼루시스틱',         'Super Leucistic',            NULL,           FALSE, 1200),
('AFRICAN_PYGMY_DORMOUSE', '버크셔',               'Berkshire',                  NULL,           FALSE, 1300),
('AFRICAN_PYGMY_DORMOUSE', '블랙',                 'Black',                      NULL,           FALSE, 1400),
('AFRICAN_PYGMY_DORMOUSE', '그레이',               'Grey',                       '그레이화이트', FALSE, 1500),

-- ═══════════════════════════════════════════════════════════════════════
--  HAMSTER_SYRIAN / 시리안햄스터  (20)
-- ═══════════════════════════════════════════════════════════════════════
('HAMSTER_SYRIAN', '노멀',         'Golden Agouti',  '골든,와일드타입',   FALSE, 100),
('HAMSTER_SYRIAN', '알비노',       'Albino',         '화이트핑크아이',    FALSE, 200),
('HAMSTER_SYRIAN', '블랙',         'Black',          NULL,                FALSE, 300),
('HAMSTER_SYRIAN', '크림',         'Cream',          NULL,                FALSE, 400),
('HAMSTER_SYRIAN', '화이트',       'White',          '블랙아이드화이트',  FALSE, 500),
('HAMSTER_SYRIAN', '옐로우',       'Yellow',         NULL,                FALSE, 600),
('HAMSTER_SYRIAN', '토터스쉘',     'Tortoiseshell',  '삼색',              FALSE, 700),
('HAMSTER_SYRIAN', '밴디드',       'Banded',         '중간띠',            FALSE, 800),
('HAMSTER_SYRIAN', '도미넌트스팟', 'Dominant Spot',  '점박이',            FALSE, 900),
('HAMSTER_SYRIAN', '시나몬',       'Cinnamon',       '레드아이드시나몬',  FALSE, 1000),
('HAMSTER_SYRIAN', '실버그레이',   'Silver Grey',    '실버',              FALSE, 1100),
('HAMSTER_SYRIAN', '러스트',       'Rust',           '기니골드',          FALSE, 1200),
('HAMSTER_SYRIAN', '다크그레이',   'Dark Grey',      NULL,                TRUE,  1300),
('HAMSTER_SYRIAN', '도브',         'Dove',           NULL,                FALSE, 1400),
('HAMSTER_SYRIAN', '허니',         'Honey',          NULL,                FALSE, 1500),
('HAMSTER_SYRIAN', '새틴',         'Satin',          '광택털',            FALSE, 1600),
('HAMSTER_SYRIAN', '롱헤어',       'Long Hair',      '앙고라,테디베어',   FALSE, 1700),
('HAMSTER_SYRIAN', '렉스',         'Rex',            '곱슬털',            FALSE, 1800),
('HAMSTER_SYRIAN', '헤어리스',     'Hairless',       '스키니',            FALSE, 1900),
('HAMSTER_SYRIAN', '로안',         'Roan',           NULL,                FALSE, 2000),

-- ═══════════════════════════════════════════════════════════════════════
--  GERBIL_MONGOLIAN / 몽골리안 저빌  (14)
-- ═══════════════════════════════════════════════════════════════════════
('GERBIL_MONGOLIAN', '골든아구티',       'Golden Agouti',    '노멀,와일드타입',   FALSE, 100),
('GERBIL_MONGOLIAN', '블랙',             'Black',            NULL,                FALSE, 200),
('GERBIL_MONGOLIAN', '아르장테',         'Argente',          '아르장테골든,루비아이', FALSE, 300),
('GERBIL_MONGOLIAN', '아르장테크림',     'Argente Cream',    '크림',              FALSE, 400),
('GERBIL_MONGOLIAN', '다크아이드허니',   'Dark Eyed Honey',  'DEH,허니',          FALSE, 500),
('GERBIL_MONGOLIAN', '넛맥',             'Nutmeg',           '넛메그',            FALSE, 600),
('GERBIL_MONGOLIAN', '도브',             'Dove',             NULL,                FALSE, 700),
('GERBIL_MONGOLIAN', '라일락',           'Lilac',            NULL,                FALSE, 800),
('GERBIL_MONGOLIAN', '핑크아이드화이트', 'Pink Eyed White',  'PEW',               FALSE, 900),
('GERBIL_MONGOLIAN', '블랙아이드화이트', 'Black Eyed White', 'BEW',               FALSE, 1000),
('GERBIL_MONGOLIAN', '시아미즈',         'Siamese',          '컬러포인트',        FALSE, 1200),
('GERBIL_MONGOLIAN', '폴라폭스',         'Polar Fox',        NULL,                FALSE, 1300),
('GERBIL_MONGOLIAN', '스팟',             'Spotted',          '스포티드',          FALSE, 1400),
('GERBIL_MONGOLIAN', '파이드',           'Pied',             NULL,                FALSE, 1500),

-- ═══════════════════════════════════════════════════════════════════════
--  CHINCHILLA / 친칠라  (15)
-- ═══════════════════════════════════════════════════════════════════════
('CHINCHILLA', '스탠다드',         'Standard',      '스탠다드그레이,노멀', FALSE, 100),
('CHINCHILLA', '베이지',           'Beige',         '헤테로베이지',        FALSE, 200),
('CHINCHILLA', '호모베이지',       'Homo Beige',    '슈퍼베이지',          FALSE, 300),
('CHINCHILLA', '블랙벨벳',         'Black Velvet',  'TOV',                 TRUE,  400),
('CHINCHILLA', '에보니',           'Ebony',         NULL,                  FALSE, 500),
('CHINCHILLA', '바이올릿',         'Violet',        NULL,                  FALSE, 600),
('CHINCHILLA', '사파이어',         'Sapphire',      NULL,                  FALSE, 700),
('CHINCHILLA', '화이트',           'White',         '모자이크화이트',      TRUE,  800),
('CHINCHILLA', '핑크화이트',       'Pink White',    '베이지화이트',        FALSE, 900),
('CHINCHILLA', '브라운벨벳',       'Brown Velvet',  'TOV베이지',           FALSE, 1000),
('CHINCHILLA', '블루다이아몬드',   'Blue Diamond',  '바이올릿사파이어',    FALSE, 1100),
('CHINCHILLA', '에보니바이올릿',   'Ebony Violet',  '바이올릿랩',          FALSE, 1200),
('CHINCHILLA', '골드바',           'Goldbar',       NULL,                  FALSE, 1300),
('CHINCHILLA', '탠',               'Tan',           '에보니베이지',        FALSE, 1400),
('CHINCHILLA', '차콜',             'Charcoal',      NULL,                  FALSE, 1500);

-- ② 종 코드 오타 가드 — 조용히 0행이 들어가는 걸 막는다
DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(DISTINCT t.species_code, ', ')
      INTO missing
      FROM tmp_morph_seed t
      LEFT JOIN species_cd s ON s.code = t.species_code
     WHERE s.id IS NULL;

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'R__02: species_cd 에 없는 종 코드 → %', missing;
    END IF;
END $$;

-- ③ 업서트
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, t.name_ko, t.name_en, t.alias_list, t.has_health_concern, t.display_order, true
FROM   tmp_morph_seed t
JOIN   species_cd s ON s.code = t.species_code
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    is_user_defined    = false,
    created_by         = NULL,
    updated_at         = NOW();

-- ④-a 목록에 없는 공식 모프 삭제 — 개체가 안 물고 있는 것만 (사용자 정의 모프 제외)
--      전 종 대상: 이번 목록에 종 자체가 빠진 옛 시드 모프도 같이 치운다.
DELETE FROM morph_cd m
USING  species_cd s
WHERE  m.species_id = s.id
  AND  m.is_user_defined = false
  AND  NOT EXISTS (
         SELECT 1 FROM tmp_morph_seed t
          WHERE t.species_code = s.code
            AND t.name_ko      = m.name_ko
       )
  AND  NOT EXISTS (SELECT 1 FROM pet_morph_rls r WHERE r.morph_id = m.id);

-- ④-b 개체가 물고 있어 못 지운 나머지는 비활성화 (fk_pet_morph_rls_morph 가 ON DELETE RESTRICT)
--      신규 선택지에선 사라지고, 이미 그 모프로 등록된 개체는 그대로 보인다.
--      개체에서 연결이 풀리면 다음 R__02 재실행 때 ④-a 가 지운다.
UPDATE morph_cd m
SET    is_active  = false,
       updated_at = NOW()
FROM   species_cd s
WHERE  m.species_id = s.id
  AND  m.is_user_defined = false
  AND  m.is_active = true
  AND  NOT EXISTS (
         SELECT 1 FROM tmp_morph_seed t
          WHERE t.species_code = s.code
            AND t.name_ko      = m.name_ko
       );

DROP TABLE tmp_morph_seed;
