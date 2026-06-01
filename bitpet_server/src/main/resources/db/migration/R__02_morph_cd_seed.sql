-- R__02_morph_cd_seed.sql
-- 모프 마스터 데이터 v1.2 (~254종)
-- R 파일: 체크섬 변경 시 Flyway가 자동 재실행
-- 전략: INSERT ON CONFLICT (species_id, name_ko) DO UPDATE → 중복 실행 가능
--
-- has_health_concern = TRUE 항목:
--   BALL_PYTHON  : 스파이더, 캐러멜알비노, 샤페인, 범블비, 슈퍼모하비스파이더
--   HOGNOSE_SNAKE: 핑크파스텔알비노(PPA)
--   BEARDED_DRAGON: 실크백
-- ─────────────────────────────────────────────────────────────────────────

-- ═══════════════════════════════════════════════════════════════════════
--  CRESTED_GECKO  (22 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',               'Normal/Wild Type',      NULL::varchar,           FALSE, 100::smallint),
    ('바이컬러',           'Bicolor',               NULL,                    FALSE, 200),
    ('달마시안',           'Dalmatian',             '달마,달마시안',         FALSE, 300),
    ('슈퍼달마시안',       'Super Dalmatian',       '슈퍼달마',              FALSE, 400),
    ('할레퀸',             'Harlequin',             '할퀸',                  FALSE, 500),
    ('핀스트라이프',       'Pinstripe',             '핀스',                  FALSE, 600),
    ('파셜핀스트라이프',   'Partial Pinstripe',     '파셜핀스',              FALSE, 700),
    ('릴리화이트',         'Lilly White',           '릴리,LW',               FALSE, 800),
    ('버킨',               'Buckskin',              NULL,                    FALSE, 900),
    ('블론드',             'Blonde',                NULL,                    FALSE, 1000),
    ('차콜',               'Charcoal',              NULL,                    FALSE, 1100),
    ('타이거',             'Tiger',                 NULL,                    FALSE, 1200),
    ('스트라이프',         'Stripe',                NULL,                    FALSE, 1300),
    ('레드',               'Red',                   NULL,                    FALSE, 1400),
    ('올리브',             'Olive',                 NULL,                    FALSE, 1500),
    ('라벤더',             'Lavender',              NULL,                    FALSE, 1600),
    ('모카',               'Mocha',                 NULL,                    FALSE, 1700),
    ('옐로우',             'Yellow',                NULL,                    FALSE, 1800),
    ('트리컬러',           'Tricolor',              NULL,                    FALSE, 1900),
    ('팬텀',               'Phantom',               NULL,                    FALSE, 2000),
    ('소프트스케일',       'Soft Scale',            NULL,                    FALSE, 2100),
    ('핀스트라이프할레퀸', 'Pinstripe Harlequin',   '핀스할퀸',              FALSE, 2200)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'CRESTED_GECKO'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  LEOPARD_GECKO  (28 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',               'Normal/Wild Type',          NULL::varchar,                   FALSE, 100::smallint),
    ('하이옐로우',         'High Yellow',               NULL,                            FALSE, 200),
    ('탄제린',             'Tangerine',                 NULL,                            FALSE, 300),
    ('하이퍼탄제린',       'Hyper Tangerine',           '하이퍼',                        FALSE, 400),
    ('알비노-트렘퍼',      'Albino (Tremper)',           '트렘퍼알비노,트렘퍼',           FALSE, 500),
    ('알비노-레이니워터',  'Albino (Rainwater)',         '레이니워터,라스베가스알비노',   FALSE, 600),
    ('알비노-벨',          'Albino (Bell)',              '벨알비노,벨',                   FALSE, 700),
    ('블리자드',           'Blizzard',                  NULL,                            FALSE, 800),
    ('패턴리스',           'Patternless',               NULL,                            FALSE, 900),
    ('이클립스',           'Eclipse',                   NULL,                            FALSE, 1000),
    ('RAPTOR',             'RAPTOR',                    '랩터',                          FALSE, 1100),
    ('RADAR',              'RADAR',                     '레이다',                        FALSE, 1200),
    ('스노우',             'Snow (Mack Snow)',           '맥스노우',                      FALSE, 1300),
    ('슈퍼스노우',         'Super Snow',                NULL,                            FALSE, 1400),
    ('멜라니스틱',         'Melanistic',                '블랙펄',                        FALSE, 1500),
    ('블랙나이트',         'Black Night',               NULL,                            FALSE, 1600),
    ('라벤더',             'Lavender',                  NULL,                            FALSE, 1700),
    ('레드스트라이프',     'Red Stripe',                NULL,                            FALSE, 1800),
    ('리버스스트라이프',   'Reverse Stripe',            NULL,                            FALSE, 1900),
    ('캐럿테일',           'Carrot Tail',               '당근꼬리',                      FALSE, 2000),
    ('자이언트',           'Giant',                     NULL,                            FALSE, 2100),
    ('슈퍼자이언트',       'Super Giant',               NULL,                            FALSE, 2200),
    ('레몬프로스트',       'Lemon Frost',               NULL,                            FALSE, 2300),
    ('블루앰버',           'Blue Amber',                NULL,                            FALSE, 2400),
    ('스텔스',             'Stealth',                   NULL,                            FALSE, 2500),
    ('선그로우',           'Sunglow',                   NULL,                            FALSE, 2600),
    ('에메라인',           'Emerine',                   NULL,                            FALSE, 2700),
    ('어메이징그레이스',   'Amazing Grace',             NULL,                            FALSE, 2800)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'LEOPARD_GECKO'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  LEACHIANUS_GT  (12 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',         'Normal/Wild Type',  NULL::varchar, FALSE, 100::smallint),
    ('블론드',       'Blonde',            NULL,          FALSE, 200),
    ('다크',         'Dark',              NULL,          FALSE, 300),
    ('블랙앤화이트', 'Black & White',     'B&W',         FALSE, 400),
    ('브라운',       'Brown',             NULL,          FALSE, 500),
    ('그린',         'Green',             NULL,          FALSE, 600),
    ('옐로우',       'Yellow',            NULL,          FALSE, 700),
    ('화이트',       'White',             NULL,          FALSE, 800),
    ('멜라니스틱',   'Melanistic',        '멜라',        FALSE, 900),
    ('릴리화이트',   'Lilly White',       '릴리,LW',     FALSE, 1000),
    ('레드',         'Red',               NULL,          FALSE, 1100),
    ('오렌지',       'Orange',            NULL,          FALSE, 1200)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'LEACHIANUS_GT'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  LEACHIANUS_ISLAND  (8 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',         'Normal/Wild Type',  NULL::varchar, FALSE, 100::smallint),
    ('블론드',       'Blonde',            NULL,          FALSE, 200),
    ('다크',         'Dark',              NULL,          FALSE, 300),
    ('블랙앤화이트', 'Black & White',     'B&W',         FALSE, 400),
    ('옐로우',       'Yellow',            NULL,          FALSE, 500),
    ('화이트',       'White',             NULL,          FALSE, 600),
    ('멜라니스틱',   'Melanistic',        '멜라',        FALSE, 700),
    ('릴리화이트',   'Lilly White',       '릴리,LW',     FALSE, 800)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'LEACHIANUS_ISLAND'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  BALL_PYTHON  (49 morphs: 34 single gene + 15 combos)
--  has_health_concern: 스파이더·캐러멜알비노·샤페인·범블비·슈퍼모하비스파이더
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    -- 단일 유전자 (34)
    ('노말',               'Normal/Wild Type',      NULL::varchar,               FALSE, 100::smallint),
    ('알비노',             'Albino',                '클래식알비노,루시스틱',     FALSE, 200),
    ('파이볼',             'Piebald',               '파이',                      FALSE, 300),
    ('스파이더',           'Spider',                NULL,                        TRUE,  400),
    ('클라운',             'Clown',                 NULL,                        FALSE, 500),
    ('모하비',             'Mojave',                NULL,                        FALSE, 600),
    ('레셀',               'Lesser',                '레서,레서플래티넘',         FALSE, 700),
    ('버터',               'Butter',                NULL,                        FALSE, 800),
    ('블랙패스텔',         'Black Pastel',          NULL,                        FALSE, 900),
    ('패스텔',             'Pastel',                NULL,                        FALSE, 1000),
    ('핀스트라이프',       'Pinstripe',             '핀스',                      FALSE, 1100),
    ('캐러멜알비노',       'Caramel Albino',        '캐러멜',                    TRUE,  1200),
    ('샤페인',             'Champagne',             NULL,                        TRUE,  1300),
    ('화이어',             'Fire',                  '화이어볼',                  FALSE, 1400),
    ('유령',               'Ghost',                 '하이포,하이포멜라니스틱',   FALSE, 1500),
    ('그래블',             'Gravel',                NULL,                        FALSE, 1600),
    ('옐로우벨리',         'Yellow Belly',          NULL,                        FALSE, 1700),
    ('바나나',             'Banana',                '코럴글로우',                FALSE, 1800),
    ('시나몬',             'Cinnamon',              NULL,                        FALSE, 1900),
    ('블러드',             'Blood',                 NULL,                        FALSE, 2000),
    ('오렌지드림',         'Orange Dream',          NULL,                        FALSE, 2100),
    ('마호가니',           'Mahogany',              NULL,                        FALSE, 2200),
    ('러소',               'Russo',                 NULL,                        FALSE, 2300),
    ('미스틱',             'Mystic',                '팬텀',                      FALSE, 2400),
    ('레오파드',           'Leopard',               NULL,                        FALSE, 2500),
    ('스칼리스헤드',       'Scaleless Head',        '스칼리스',                  FALSE, 2600),
    ('제네틱스트라이프',   'Genetic Stripe',        '스트라이프',                FALSE, 2700),
    ('울트라멜',           'Ultramel',              '울트라',                    FALSE, 2800),
    ('캔디',               'Candy',                 '캔디알비노',                FALSE, 2900),
    ('토피',               'Toffee',                '토피알비노',                FALSE, 3000),
    ('아스팔트',           'Asphalt',               NULL,                        FALSE, 3100),
    ('바닐라',             'Vanilla',               NULL,                        FALSE, 3200),
    ('먼순',               'Monsoon',               NULL,                        FALSE, 3300),
    ('스텔스',             'Stealth',               NULL,                        FALSE, 3400),
    -- 콤보 모프 (15)
    ('범블비',             'Bumble Bee',            '스파이더패스텔',            TRUE,  3500),
    ('슈퍼모하비스파이더', 'Super Mojave Spider',   '슈퍼모하비',                TRUE,  3600),
    ('블루아이루시스틱',   'Blue Eyed Leucistic',   'BEL,블루아이,루시스틱',     FALSE, 3700),
    ('아이보리',           'Ivory',                 NULL,                        FALSE, 3800),
    ('퍼플패션',           'Purple Passion',        NULL,                        FALSE, 3900),
    ('슈퍼블랙패스텔',     'Super Black Pastel',    NULL,                        FALSE, 4000),
    ('슈퍼패스텔',         'Super Pastel',          NULL,                        FALSE, 4100),
    ('알비노파이볼',       'Albino Piebald',        '알비노파이',                FALSE, 4200),
    ('클라운파이볼',       'Clown Piebald',         '클라운파이',                FALSE, 4300),
    ('바나나파이볼',       'Banana Piebald',        '바나나파이',                FALSE, 4400),
    ('클라운알비노',       'Clown Albino',          NULL,                        FALSE, 4500),
    ('블래스트',           'Blast',                 '패스텔파이',                FALSE, 4600),
    ('오렌지드림패스텔',   'Orange Dream Pastel',   NULL,                        FALSE, 4700),
    ('퍼플패션파이볼',     'Purple Passion Piebald', NULL,                       FALSE, 4800),
    ('클라운블랙패스텔',   'Clown Black Pastel',    NULL,                        FALSE, 4900)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'BALL_PYTHON'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  CORN_SNAKE  (25 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',             'Normal/Wild Type',    NULL::varchar,          FALSE, 100::smallint),
    ('알비노',           'Albino',              '아멜라니스틱,아멜',    FALSE, 200),
    ('아네리',           'Anerythristic',       '블랙알비노,아네리',    FALSE, 300),
    ('하이포',           'Hypomelanistic',      '하이포멜라니스틱',     FALSE, 400),
    ('모틀리',           'Motley',              NULL,                   FALSE, 500),
    ('스트라이프',       'Stripe',              NULL,                   FALSE, 600),
    ('테셀라',           'Tessera',             NULL,                   FALSE, 700),
    ('블리자드',         'Blizzard',            NULL,                   FALSE, 800),
    ('스노우',           'Snow',                NULL,                   FALSE, 900),
    ('오팔',             'Opal',                NULL,                   FALSE, 1000),
    ('블러드레드',       'Bloodred',            '블러드',               FALSE, 1100),
    ('크림시클',         'Creamsicle',          NULL,                   FALSE, 1200),
    ('에메랄드',         'Emerald',             NULL,                   FALSE, 1300),
    ('라바',             'Lava',                NULL,                   FALSE, 1400),
    ('버터스카치',       'Butterscotch',        NULL,                   FALSE, 1500),
    ('코랄스노우',       'Coral Snow',          NULL,                   FALSE, 1600),
    ('오리온',           'Orion',               NULL,                   FALSE, 1700),
    ('팬텀',             'Phantom',             NULL,                   FALSE, 1800),
    ('민트',             'Mint',                NULL,                   FALSE, 1900),
    ('카라멜',           'Caramel',             NULL,                   FALSE, 2000),
    ('마이애미페이즈',   'Miami Phase',         '마이애미',             FALSE, 2100),
    ('오키티',           'Okeetee',             NULL,                   FALSE, 2200),
    ('리버스오키티',     'Reverse Okeetee',     NULL,                   FALSE, 2300),
    ('선그로우',         'Sunglow',             NULL,                   FALSE, 2400),
    ('그래파이트',       'Graphite',            NULL,                   FALSE, 2500)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'CORN_SNAKE'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  CALIFORNIA_KINGSNAKE  (15 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',           'Normal/Wild Type',    NULL::varchar,   FALSE, 100::smallint),
    ('알비노',         'Albino',              '사막알비노',    FALSE, 200),
    ('라벤더',         'Lavender',            NULL,            FALSE, 300),
    ('하이포',         'Hypomelanistic',      '하이포멜라',    FALSE, 400),
    ('스트라이프',     'Stripe',              NULL,            FALSE, 500),
    ('리버스스트라이프','Reverse Stripe',     NULL,            FALSE, 600),
    ('애버런트',       'Aberrant',            '애버',          FALSE, 700),
    ('밴디드',         'Banded',              NULL,            FALSE, 800),
    ('블론드',         'Blonde',              NULL,            FALSE, 900),
    ('고스트',         'Ghost',               '고스트알비노',  FALSE, 1000),
    ('패턴리스',       'Patternless',         NULL,            FALSE, 1100),
    ('브라운',         'Brown',               NULL,            FALSE, 1200),
    ('알비노애버런트', 'Albino Aberrant',     NULL,            FALSE, 1300),
    ('하이포스트라이프','Hypo Stripe',        NULL,            FALSE, 1400),
    ('모자이크',       'Mosaic',              '얼룩무늬',      FALSE, 1500)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'CALIFORNIA_KINGSNAKE'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  HOGNOSE_SNAKE  (20 morphs)
--  has_health_concern: 핑크파스텔알비노(PPA)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노말',               'Normal/Wild Type',      NULL::varchar,       FALSE, 100::smallint),
    ('알비노',             'Albino',                '클래식알비노',      FALSE, 200),
    ('하이포',             'Hypo',                  '에반스하이포',      FALSE, 300),
    ('슈퍼하이포',         'Super Hypo',            NULL,                FALSE, 400),
    ('패스텔',             'Pastel',                '이소벨',            FALSE, 500),
    ('핑크파스텔알비노',   'Pink Pastel Albino',    'PPA,핑크PPA',       TRUE,  600),
    ('라벤더',             'Lavender',              NULL,                FALSE, 700),
    ('아나콘다',           'Anaconda',              NULL,                FALSE, 800),
    ('슈퍼콘다',           'Super Conda',           '슈퍼아나콘다',      FALSE, 900),
    ('토피',               'Toffee',                NULL,                FALSE, 1000),
    ('아틱',               'Arctic',                NULL,                FALSE, 1100),
    ('그린',               'Green',                 NULL,                FALSE, 1200),
    ('코랄',               'Coral',                 NULL,                FALSE, 1300),
    ('레몬',               'Lemon',                 NULL,                FALSE, 1400),
    ('블론드',             'Blonde',                NULL,                FALSE, 1500),
    ('액산틱',             'Axanthic',              '옥시,악산틱',       FALSE, 1600),
    ('알비노하이포',       'Albino Hypo',           NULL,                FALSE, 1700),
    ('패스텔아나콘다',     'Pastel Anaconda',       NULL,                FALSE, 1800),
    ('라벤더아나콘다',     'Lavender Anaconda',     NULL,                FALSE, 1900),
    ('슈퍼알비노',         'Super Albino',          NULL,                FALSE, 2000)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'HOGNOSE_SNAKE'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  BEARDED_DRAGON  (30 morphs)
--  has_health_concern: 실크백
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('클래식',           'Classic/Normal',        NULL::varchar,       FALSE, 100::smallint),
    ('레더백',           'Leatherback',           '리더백',            FALSE, 200),
    ('실크백',           'Silkback',              '실키',              TRUE,  300),
    ('던너',             'Dunner',                NULL,                FALSE, 400),
    ('트랜스루센트',     'Translucent',           '트랜스',            FALSE, 500),
    ('제로',             'Zero',                  NULL,                FALSE, 600),
    ('위트블리츠',       'Witblits',              NULL,                FALSE, 700),
    ('하이포',           'Hypo',                  '하이포멜라니스틱',  FALSE, 800),
    ('알비노',           'Albino',                NULL,                FALSE, 900),
    ('레드',             'Red',                   '레드모프',          FALSE, 1000),
    ('오렌지',           'Orange',                NULL,                FALSE, 1100),
    ('옐로우',           'Yellow',                NULL,                FALSE, 1200),
    ('타이거',           'Tiger',                 NULL,                FALSE, 1300),
    ('블러드레드',       'Bloodred',              '블러드',            FALSE, 1400),
    ('레더백하이포',     'Leatherback Hypo',      NULL,                FALSE, 1500),
    ('하이포제로',       'Hypo Zero',             NULL,                FALSE, 1600),
    ('하이포위트블리츠', 'Hypo Witblits',         NULL,                FALSE, 1700),
    ('선버스트',         'Sunburst',              NULL,                FALSE, 1800),
    ('선라이즈',         'Sunrise',               NULL,                FALSE, 1900),
    ('블루바',           'Blue Bar',              NULL,                FALSE, 2000),
    ('화이트',           'White',                 NULL,                FALSE, 2100),
    ('스노우',           'Snow',                  NULL,                FALSE, 2200),
    ('아이스',           'Ice',                   NULL,                FALSE, 2300),
    ('레더백레드',       'Leatherback Red',       NULL,                FALSE, 2400),
    ('레더백트랜스',     'Leatherback Translucent', NULL,              FALSE, 2500),
    ('던너하이포',       'Dunner Hypo',           NULL,                FALSE, 2600),
    ('체리레드',         'Cherry Red',            NULL,                FALSE, 2700),
    ('로즈골드',         'Rose Gold',             NULL,                FALSE, 2800),
    ('사파이어',         'Sapphire',              NULL,                FALSE, 2900),
    ('트랜스하이포',     'Translucent Hypo',      NULL,                FALSE, 3000)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'BEARDED_DRAGON'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  BLUE_TONGUE_SKINK  (25 morphs / locality variants)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('노던',           'Northern',              '노던블루텅',          FALSE, 100::smallint),
    ('이리안자야',     'Irian Jaya',            '이리안,IJ',           FALSE, 200),
    ('인도네시안',     'Indonesian',            '술라웨시',            FALSE, 300),
    ('할마헤라',       'Halmahera',             NULL,                  FALSE, 400),
    ('탄임바르',       'Tanimbar',              NULL,                  FALSE, 500),
    ('메라우케',       'Merauke',               NULL,                  FALSE, 600),
    ('케이아일랜드',   'Kei Island',            '케이',                FALSE, 700),
    ('하이포',         'Hypo',                  '하이포노던',          FALSE, 800),
    ('알비노',         'Albino',                NULL,                  FALSE, 900),
    ('카라멜',         'Caramel',               '카라멜노던',          FALSE, 1000),
    ('블루',           'Blue',                  NULL,                  FALSE, 1100),
    ('옐로우',         'Yellow',                NULL,                  FALSE, 1200),
    ('오렌지',         'Orange',                NULL,                  FALSE, 1300),
    ('초콜릿',         'Chocolate',             NULL,                  FALSE, 1400),
    ('클래식',         'Classic',               '올드클래식',          FALSE, 1500),
    ('아이보리',       'Ivory',                 '하이포알비노',        FALSE, 1600),
    ('스노우',         'Snow',                  NULL,                  FALSE, 1700),
    ('고스트',         'Ghost',                 NULL,                  FALSE, 1800),
    ('실버',           'Silver',                NULL,                  FALSE, 1900),
    ('팬텀',           'Phantom',               NULL,                  FALSE, 2000),
    ('타이거',         'Tiger',                 NULL,                  FALSE, 2100),
    ('레더백',         'Leatherback',           NULL,                  FALSE, 2200),
    ('스무스스케일',   'Smooth Scale',          NULL,                  FALSE, 2300),
    ('레드',           'Red',                   NULL,                  FALSE, 2400),
    ('그래니트',       'Granite',               NULL,                  FALSE, 2500)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'BLUE_TONGUE_SKINK'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  ARGENTINE_BLACK_WHITE_TEGU  (12 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('클래식',           'Classic Black & White',     'B&W,클래식BW',    FALSE, 100::smallint),
    ('하이화이트',       'High White',                '하이W',            FALSE, 200),
    ('엑스트림하이화이트','Extreme High White',       '엑스트림',         FALSE, 300),
    ('알비노',           'Albino',                    NULL,               FALSE, 400),
    ('알비노하이화이트', 'Albino High White',         NULL,               FALSE, 500),
    ('블루',             'Blue',                      '블루테구',         FALSE, 600),
    ('블루하이화이트',   'Blue High White',           NULL,               FALSE, 700),
    ('그라니트',         'Granite',                   NULL,               FALSE, 800),
    ('실버',             'Silver',                    NULL,               FALSE, 900),
    ('파이드',           'Pied',                      '파이',             FALSE, 1000),
    ('글로우',           'Glow',                      NULL,               FALSE, 1100),
    ('왁스',             'Wax',                       NULL,               FALSE, 1200)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'ARGENTINE_BLACK_WHITE_TEGU'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();

-- ═══════════════════════════════════════════════════════════════════════
--  RED_TEGU  (8 morphs)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO morph_cd (species_id, name_ko, name_en, alias_list, has_health_concern, display_order, is_active)
SELECT s.id, v.name_ko, v.name_en, v.alias_list, v.has_health_concern, v.display_order, true
FROM   species_cd s
CROSS  JOIN (VALUES
    ('클래식레드',       'Classic Red',           NULL::varchar, FALSE, 100::smallint),
    ('하이레드',         'High Red',              NULL,          FALSE, 200),
    ('알비노',           'Albino',                NULL,          FALSE, 300),
    ('하이화이트',       'High White',            NULL,          FALSE, 400),
    ('알비노하이화이트', 'Albino High White',     NULL,          FALSE, 500),
    ('블루레드',         'Blue Red',              NULL,          FALSE, 600),
    ('골든',             'Golden',                NULL,          FALSE, 700),
    ('레드알비노하이화이트','Red Albino High White', NULL,       FALSE, 800)
) AS v(name_ko, name_en, alias_list, has_health_concern, display_order)
WHERE  s.code = 'RED_TEGU'
ON CONFLICT (species_id, name_ko) DO UPDATE SET
    name_en            = EXCLUDED.name_en,
    alias_list         = EXCLUDED.alias_list,
    has_health_concern = EXCLUDED.has_health_concern,
    display_order      = EXCLUDED.display_order,
    is_active          = EXCLUDED.is_active,
    updated_at         = NOW();
