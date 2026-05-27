-- R__01_species_cd_seed.sql
-- 파충류·양서류 종 마스터 데이터 v1.1 (148종)
-- R 파일: 체크섬 변경 시 Flyway가 자동 재실행
-- 전략: INSERT ON CONFLICT (code) DO UPDATE → FK 참조 안전, 중복 실행 가능
--
-- category: R=파충류, A=양서류
-- subcategory: GECKO / LIZARD / CHAMELEON / SNAKE / TURTLE / FROG / NEWT
-- display_order: subcategory 내 100단위 채번 (일부 예외 존재)
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO species_cd
    (code, category, subcategory, name_ko, name_en, scientific_name, display_order, is_active)
VALUES

-- ═══════════════════════════════════════════════════════════════════════
--  파충류 (R)  ·  GECKO  38종
-- ═══════════════════════════════════════════════════════════════════════
('LEOPARD_GECKO',           'R', 'GECKO', '레오파드게코',           'Leopard Gecko',                   'Eublepharis macularius',                  100,  true),
('CRESTED_GECKO',           'R', 'GECKO', '크레스티드게코',         'Crested Gecko',                   'Correlophus ciliatus',                    200,  true),
('GARGOYLE_GECKO',          'R', 'GECKO', '가고일게코',             'Gargoyle Gecko',                  'Rhacodactylus auriculatus',               300,  true),
('AFRICAN_FAT_TAILED_GECKO','R', 'GECKO', '팻테일게코',             'African Fat-tailed Gecko',        'Hemitheconyx caudicinctus',               400,  true),
('TOKAY_GECKO',             'R', 'GECKO', '토케이게코',             'Tokay Gecko',                     'Gekko gecko',                             500,  true),
('GIANT_DAY_GECKO',         'R', 'GECKO', '자이언트데이게코',       'Giant Day Gecko',                 'Phelsuma grandis',                        600,  true),
('GOLD_DUST_DAY_GECKO',     'R', 'GECKO', '골드더스트데이게코',     'Gold Dust Day Gecko',             'Phelsuma laticauda',                      700,  true),
('NEON_DAY_GECKO',          'R', 'GECKO', '네온데이게코',           'Neon Day Gecko',                  'Phelsuma klemmeri',                       800,  true),
('PEACOCK_DAY_GECKO',       'R', 'GECKO', '피콕데이게코',           'Peacock Day Gecko',               'Phelsuma quadriocellata',                 900,  true),
('LINED_DAY_GECKO',         'R', 'GECKO', '라인데이게코',           'Lined Day Gecko',                 'Phelsuma lineata',                        1000, true),
('KNOB_TAILED_GECKO',       'R', 'GECKO', '납테일게코',             'Knob-tailed Gecko',               'Nephrurus levis',                         1100, true),
('VIPER_GECKO',             'R', 'GECKO', '바이퍼게코',             'Viper Gecko',                     'Hemidactylus imbricatus',                 1200, true),
('MOURNING_GECKO',          'R', 'GECKO', '모어닝게코',             'Mourning Gecko',                  'Lepidodactylus lugubris',                 1300, true),
('CHAHOUA_GECKO',           'R', 'GECKO', '차화게코',               'Chahoua Gecko',                   'Mniarogekko chahoua',                     1400, true),
('LEACHIANUS_GT',           'R', 'GECKO', '리키에너스GT',           'Leachianus Gecko (Grande Terre)', 'Rhacodactylus leachianus (GT)',            1500, true),
('LEACHIANUS_ISLAND',       'R', 'GECKO', '리키에너스아일랜드',     'Leachianus Gecko (Island)',       'Rhacodactylus leachianus (Island)',        1600, true),
('FROG_EYED_GECKO',         'R', 'GECKO', '프록아이게코',           'Frog-eyed Gecko',                 'Teratoscincus scincus',                   1700, true),
('HELMETED_GECKO',          'R', 'GECKO', '호주헬멧티드게코',       'Helmeted Gecko',                  'Diplodactylus galeatus',                  1800, true),
('THICK_TAILED_GECKO',      'R', 'GECKO', '틱테일게코',             'Thick-tailed Gecko',              'Underwoodisaurus milii',                  1900, true),
('ANGRAMAINYU_GECKO',       'R', 'GECKO', '앙그라마이뉴',           'Angramainyu Gecko',               'Eublepharis angramainyu',                 2000, true),
('DUNE_GECKO',              'R', 'GECKO', '듄게코',                 'Dune Gecko',                      'Stenodactylus petrii',                    2100, true),
('ELEGANT_GECKO',           'R', 'GECKO', '엘레강스게코',           'Elegant Gecko',                   'Stenodactylus sthenodactylus',            2200, true),
('MOORISH_GECKO',           'R', 'GECKO', '무리쉬게코',             'Moorish Gecko',                   'Tarentola mauritanica',                   2300, true),
('PICTUS_GECKO',            'R', 'GECKO', '펫테일게코',             'Pictus Gecko',                    'Paroedura picta',                         2400, true),
('FISH_SCALE_GECKO',        'R', 'GECKO', '피쉬스케일게코',         'Fish Scale Gecko',                'Geckolepis megalepis',                    2500, true),
('SARASIN_GECKO',           'R', 'GECKO', '사라신게코',             'Sarasin''s Gecko',                'Correlophus sarasinorum',                 2600, true),
('CHAMELEON_GECKO',         'R', 'GECKO', '카멜레온게코',           'Chameleon Gecko',                 'Eurydactylodes agricolae',                2700, true),
('BIBRON_GECKO',            'R', 'GECKO', '비브론게코',             'Bibron''s Gecko',                 'Chondrodactylus bibronii',                2800, true),
('WHITE_LINED_GECKO',       'R', 'GECKO', '화이트라인드게코',       'White-lined Gecko',               'Gekko vittatus',                          2900, true),
('GOLDEN_GECKO',            'R', 'GECKO', '골든게코',               'Golden Gecko',                    'Gekko badenii',                           3000, true),
('CRESTED_DAY_GECKO',       'R', 'GECKO', '크레스티드데이게코',     'Crested Day Gecko',               'Phelsuma guimbeaui',                      3100, true),
('LEAF_TAILED_GECKO',       'R', 'GECKO', '리프테일게코',           'Leaf-tailed Gecko',               'Uroplatus phantasticus',                  3200, true),
('HOUSE_GECKO',             'R', 'GECKO', '하우스게코',             'Common House Gecko',              'Hemidactylus frenatus',                   3400, true),
('FLYING_GECKO',            'R', 'GECKO', '플라잉게코',             'Flying Gecko',                    'Gekko kuhli',                             3600, true),
('MADAGASCAR_GROUND_GECKO', 'R', 'GECKO', '마다가스카르그라운드게코','Madagascar Ground Gecko',        'Paroedura androyensis',                   3700, true),
('BANDED_GECKO',            'R', 'GECKO', '밴디드게코',             'Western Banded Gecko',            'Coleonyx variegatus',                     3800, true),
('CAVE_GECKO',              'R', 'GECKO', '케이브게코',             'Cave Gecko',                      'Goniurosaurus luii',                      3900, true),
('STRIPED_DAY_GECKO',       'R', 'GECKO', '스트라이프드데이게코',   'Striped Day Gecko',               'Phelsuma lineata bifasciata',             4000, true),

-- ═══════════════════════════════════════════════════════════════════════
--  파충류 (R)  ·  LIZARD  35종
-- ═══════════════════════════════════════════════════════════════════════
('BEARDED_DRAGON',              'R', 'LIZARD', '비어디드래곤',               'Bearded Dragon',                       'Pogona vitticeps',                    100,  true),
('BLUE_TONGUE_SKINK',           'R', 'LIZARD', '블루텅스킨크',               'Blue-tongued Skink',                   'Tiliqua scincoides',                  200,  true),
('ARGENTINE_BLACK_WHITE_TEGU',  'R', 'LIZARD', '아르헨틴블랙앤화이트테구',   'Argentine Black & White Tegu',         'Salvator merianae',                   300,  true),
('RED_TEGU',                    'R', 'LIZARD', '레드테구',                   'Red Tegu',                             'Salvator rufescens',                  400,  true),
('SAVANNAH_MONITOR',            'R', 'LIZARD', '사바나모니터',               'Savannah Monitor',                     'Varanus exanthematicus',              500,  true),
('ACKIE_MONITOR',               'R', 'LIZARD', '액키모니터',                 'Ackie Monitor',                        'Varanus acanthurus',                  600,  true),
('GREEN_IGUANA',                'R', 'LIZARD', '그린이구아나',               'Green Iguana',                         'Iguana iguana',                       700,  true),
('RHINOCEROS_IGUANA',           'R', 'LIZARD', '라이노세로스이구아나',       'Rhinoceros Iguana',                    'Cyclura cornuta',                     800,  true),
('UROMASTYX',                   'R', 'LIZARD', '유로마스틱스',               'Uromastyx',                            'Uromastyx aegyptia',                  900,  true),
('SAND_FISH_SKINK',             'R', 'LIZARD', '샌드피쉬스킨크',             'Sandfish Skink',                       'Scincus scincus',                     1000, true),
('LEGLESS_LIZARD',              'R', 'LIZARD', '레그리스리자드',             'Legless Lizard',                       'Anguis fragilis',                     1100, true),
('CHINESE_WATER_DRAGON',        'R', 'LIZARD', '차이니즈워터드래곤',         'Chinese Water Dragon',                 'Physignathus cocincinus',             1200, true),
('FRILLED_LIZARD',              'R', 'LIZARD', '프릴드리자드',               'Frilled Lizard',                       'Chlamydosaurus kingii',               1300, true),
('LONG_TAILED_LIZARD',          'R', 'LIZARD', '롱테일리자드',               'Long-tailed Grass Lizard',             'Takydromus sexlineatus',              1400, true),
('GREEN_ANOLE',                 'R', 'LIZARD', '그린에놀',                   'Green Anole',                          'Anolis carolinensis',                 1500, true),
('BROWN_ANOLE',                 'R', 'LIZARD', '브라운에놀',                 'Brown Anole',                          'Anolis sagrei',                       1600, true),
('KNIGHT_ANOLE',                'R', 'LIZARD', '나이트에놀',                 'Knight Anole',                         'Anolis equestris',                    1700, true),
('FIRE_SKINK',                  'R', 'LIZARD', '파이어스킨크',               'Fire Skink',                           'Lepidothyris fernandi',               1800, true),
('SCHNEIDER_SKINK',             'R', 'LIZARD', '슈나이더스킨크',             'Schneider''s Skink',                   'Eumeces schneideri',                  1900, true),
('PINK_TONGUE_SKINK',           'R', 'LIZARD', '핑크텅스킨크',               'Pink-tongued Skink',                   'Cyclodomorphus gerrardii',            2000, true),
('SHINGLEBACK_SKINK',           'R', 'LIZARD', '슁글백스킨크',               'Shingleback Skink',                    'Tiliqua rugosa',                      2100, true),
('CURLY_TAILED_LIZARD',         'R', 'LIZARD', '컬리테일리자드',             'Curly-tailed Lizard',                  'Leiocephalus carinatus',              2200, true),
('COLLARED_LIZARD',             'R', 'LIZARD', '칼라드리자드',               'Collared Lizard',                      'Crotaphytus collaris',                2300, true),
('MALI_UROMASTYX',              'R', 'LIZARD', '말리유로마스틱스',           'Mali Uromastyx',                       'Uromastyx dispar maliensis',          2400, true),
('ORNATE_UROMASTYX',            'R', 'LIZARD', '오네이트유로마스틱스',       'Ornate Uromastyx',                     'Uromastyx ornata',                    2500, true),
('NILE_MONITOR',                'R', 'LIZARD', '나일모니터',                 'Nile Monitor',                         'Varanus niloticus',                   2600, true),
('ASIAN_WATER_MONITOR',         'R', 'LIZARD', '아시안워터모니터',           'Asian Water Monitor',                  'Varanus salvator',                    2700, true),
('EMERALD_TREE_MONITOR',        'R', 'LIZARD', '에메랄드트리모니터',         'Emerald Tree Monitor',                 'Varanus prasinus',                    2800, true),
('CUBAN_KNIGHT_ANOLE',          'R', 'LIZARD', '쿠반나이트에놀',             'Cuban Knight Anole',                   'Anolis equestris equestris',          2900, true),
('PRASINA_LIZARD',              'R', 'LIZARD', '프라시나',                   'Green Keel-Bellied Lizard',            'Gastropholis prasina',                3100, true),
('ABRONIA',                     'R', 'LIZARD', '아브로니아',                 'Arboreal Alligator Lizard',            'Abronia spp.',                        3200, true),
('EGERNIA_EPSISOLUS',           'R', 'LIZARD', '에게르니아 앱시솔루스',      'Eastern Pilbara Spiny-tailed Skink',   'Egernia epsisolus',                   3300, true),
('EGERNIA_CYGNITOS',            'R', 'LIZARD', '에게르니아 시그니토스',      'Western Pilbara Spiny-tailed Skink',   'Egernia cygnitos',                    3400, true),
('BLACK_THROAT_MONITOR',        'R', 'LIZARD', '블랙쓰롯모니터',             'Black-throated Monitor',               'Varanus albigularis ionidesi',        3500, true),
('QUINCE_MONITOR',              'R', 'LIZARD', '꾸잉모니터',                 'Quince Monitor',                       'Varanus cumingi',                     3600, true),

-- ═══════════════════════════════════════════════════════════════════════
--  파충류 (R)  ·  CHAMELEON  8종
-- ═══════════════════════════════════════════════════════════════════════
('VEILED_CHAMELEON',  'R', 'CHAMELEON', '베일드카멜레온',  'Veiled Chameleon',     'Chamaeleo calyptratus',  100, true),
('PANTHER_CHAMELEON', 'R', 'CHAMELEON', '팬서카멜레온',   'Panther Chameleon',    'Furcifer pardalis',      200, true),
('JACKSON_CHAMELEON', 'R', 'CHAMELEON', '잭슨카멜레온',   'Jackson''s Chameleon', 'Trioceros jacksonii',    300, true),
('PYGMY_CHAMELEON',   'R', 'CHAMELEON', '피그미카멜레온', 'Pygmy Chameleon',      'Rhampholeon spectrum',   400, true),
('FISCHER_CHAMELEON', 'R', 'CHAMELEON', '피셔카멜레온',   'Fischer''s Chameleon', 'Kinyongia fischeri',     500, true),
('MELLER_CHAMELEON',  'R', 'CHAMELEON', '멜러카멜레온',   'Meller''s Chameleon',  'Trioceros melleri',      600, true),
('CARPET_CHAMELEON',  'R', 'CHAMELEON', '카펫카멜레온',   'Carpet Chameleon',     'Furcifer lateralis',     700, true),
('SENEGAL_CHAMELEON', 'R', 'CHAMELEON', '세네갈카멜레온', 'Senegal Chameleon',    'Chamaeleo senegalensis', 900, true),

-- ═══════════════════════════════════════════════════════════════════════
--  파충류 (R)  ·  SNAKE  20종
-- ═══════════════════════════════════════════════════════════════════════
('CORN_SNAKE',              'R', 'SNAKE', '콘스네이크',         'Corn Snake',               'Pantherophis guttatus',         100,  true),
('BALL_PYTHON',             'R', 'SNAKE', '볼파이톤',           'Ball Python',              'Python regius',                 200,  true),
('HOGNOSE_SNAKE',           'R', 'SNAKE', '호그노즈',           'Western Hognose Snake',    'Heterodon nasicus',             300,  true),
('KENYAN_SAND_BOA',         'R', 'SNAKE', '케냐샌드보아',       'Kenyan Sand Boa',          'Eryx colubrinus',               400,  true),
('ROSY_BOA',                'R', 'SNAKE', '로지보아',           'Rosy Boa',                 'Lichanura trivirgata',          500,  true),
('CALIFORNIA_KINGSNAKE',    'R', 'SNAKE', '캘리포니아킹스네이크','California Kingsnake',     'Lampropeltis californiae',      600,  true),
('MILK_SNAKE',              'R', 'SNAKE', '밀크스네이크',       'Milk Snake',               'Lampropeltis triangulum',       700,  true),
('GARTER_SNAKE',            'R', 'SNAKE', '가터스네이크',       'Common Garter Snake',      'Thamnophis sirtalis',           800,  true),
('RAINBOW_BOA',             'R', 'SNAKE', '레인보우보아',       'Brazilian Rainbow Boa',    'Epicrates cenchria',            900,  true),
('CARPET_PYTHON',           'R', 'SNAKE', '카펫파이톤',         'Carpet Python',            'Morelia spilota',               1000, true),
('CHILDREN_PYTHON',         'R', 'SNAKE', '칠드런파이톤',       'Children''s Python',       'Antaresia childreni',           1100, true),
('SPOTTED_PYTHON',          'R', 'SNAKE', '스파티드파이톤',     'Spotted Python',           'Antaresia maculosa',            1200, true),
('BLOOD_PYTHON',            'R', 'SNAKE', '블러드파이톤',       'Blood Python',             'Python brongersmai',            1300, true),
('WOMA_PYTHON',             'R', 'SNAKE', '워마파이톤',         'Woma Python',              'Aspidites ramsayi',             1400, true),
('GREEN_TREE_PYTHON',       'R', 'SNAKE', '그린트리파이톤',     'Green Tree Python',        'Morelia viridis',               1500, true),
('EMERALD_TREE_BOA',        'R', 'SNAKE', '에메랄드트리보아',   'Emerald Tree Boa',         'Corallus caninus',              1600, true),
('AMAZON_TREE_BOA',         'R', 'SNAKE', '아마존트리보아',     'Amazon Tree Boa',          'Corallus hortulanus',           1700, true),
('JAPANESE_RAT_SNAKE',      'R', 'SNAKE', '재패니즈랫스네이크', 'Japanese Rat Snake',       'Elaphe climacophora',           2200, true),
('TAIWAN_BEAUTY_RAT_SNAKE', 'R', 'SNAKE', '타이완뷰티랫스네이크','Taiwan Beauty Rat Snake',  'Orthriophis taeniurus friesi',  2300, true),
('RUSSIAN_RAT_SNAKE',       'R', 'SNAKE', '러시안랫스네이크',   'Russian Rat Snake',        'Elaphe schrenckii',             2400, true),

-- ═══════════════════════════════════════════════════════════════════════
--  파충류 (R)  ·  TURTLE  16종
-- ═══════════════════════════════════════════════════════════════════════
('RUSSIAN_TORTOISE',      'R', 'TURTLE', '러시안육지거북',       'Russian Tortoise',       'Testudo horsfieldii',                100,  true),
('HERMANN_TORTOISE',      'R', 'TURTLE', '헤르만육지거북',       'Hermann''s Tortoise',    'Testudo hermanni',                   200,  true),
('GREEK_TORTOISE',        'R', 'TURTLE', '그리스육지거북',       'Greek Tortoise',         'Testudo graeca',                     300,  true),
('SULCATA_TORTOISE',      'R', 'TURTLE', '설카타육지거북',       'Sulcata Tortoise',       'Centrochelys sulcata',               400,  true),
('LEOPARD_TORTOISE',      'R', 'TURTLE', '레오파드육지거북',     'Leopard Tortoise',       'Stigmochelys pardalis',              500,  true),
('RED_FOOTED_TORTOISE',   'R', 'TURTLE', '레드풋육지거북',       'Red-footed Tortoise',    'Chelonoidis carbonarius',            600,  true),
('YELLOW_FOOTED_TORTOISE','R', 'TURTLE', '옐로우풋육지거북',     'Yellow-footed Tortoise', 'Chelonoidis denticulatus',           700,  true),
('DIAMONDBACK_TERRAPIN',  'R', 'TURTLE', '다이아몬드백테라핀',   'Diamondback Terrapin',   'Malaclemys terrapin',                800,  true),
('MAP_TURTLE',            'R', 'TURTLE', '맵터틀',               'Mississippi Map Turtle', 'Graptemys pseudogeographica',        850,  true),
('GUYANA_TERRAPIN',       'R', 'TURTLE', '그마라테라핀',         'Gibba Toad-headed Turtle','Mesoclemmys gibba',                 900,  true),
('YELLOW_BELLIED_SLIDER', 'R', 'TURTLE', '옐로우벨리슬라이더',   'Yellow-bellied Slider',  'Trachemys scripta scripta',          1000, true),
('MUSK_TURTLE',           'R', 'TURTLE', '머스크터틀',           'Common Musk Turtle',     'Sternotherus odoratus',              1100, true),
('MUD_TURTLE',            'R', 'TURTLE', '머드터틀',             'Eastern Mud Turtle',     'Kinosternon subrubrum',              1200, true),
('MATA_MATA_TURTLE',      'R', 'TURTLE', '마타마타거북',         'Mata Mata Turtle',       'Chelus fimbriata',                   1300, true),
('PIG_NOSED_TURTLE',      'R', 'TURTLE', '피그노즈거북',         'Pig-nosed Turtle',       'Carettochelys insculpta',            1400, true),
('BOX_TURTLE',            'R', 'TURTLE', '박스터틀',             'Eastern Box Turtle',     'Terrapene carolina',                 1500, true),

-- ═══════════════════════════════════════════════════════════════════════
--  양서류 (A)  ·  FROG  22종
-- ═══════════════════════════════════════════════════════════════════════
('WHITE_TREE_FROG',         'A', 'FROG', '화이트트리프록',         'White''s Tree Frog',         'Litoria caerulea',                    100,  true),
('MILK_FROG',               'A', 'FROG', '밀크프록',               'Amazon Milk Frog',            'Trachycephalus resinifictrix',        200,  true),
('PACMAN_FROG',             'A', 'FROG', '팩맨프록',               'Pacman Frog',                 'Ceratophrys ornata',                  300,  true),
('RED_EYED_TREE_FROG',      'A', 'FROG', '레드아이트리프록',       'Red-eyed Tree Frog',          'Agalychnis callidryas',               400,  true),
('TOMATO_FROG',             'A', 'FROG', '토마토프록',             'Tomato Frog',                 'Dyscophus antongilii',                500,  true),
('AFRICAN_BULLFROG',        'A', 'FROG', '아프리칸불프록',         'African Bullfrog',            'Pyxicephalus adspersus',              600,  true),
('WAXY_MONKEY_FROG',        'A', 'FROG', '왁시몽키프록',           'Waxy Monkey Frog',            'Phyllomedusa sauvagii',               700,  true),
('VIETNAMESE_MOSSY_FROG',   'A', 'FROG', '베트남이끼개구리',       'Vietnamese Mossy Frog',       'Theloderma corticale',                800,  true),
('DART_FROG_BLUE',          'A', 'FROG', '블루다트프록',           'Blue Poison Dart Frog',       'Dendrobates tinctorius azureus',      900,  true),
('DART_FROG_GOLDEN',        'A', 'FROG', '골든다트프록',           'Golden Poison Dart Frog',     'Phyllobates terribilis',              1000, true),
('DART_FROG_GREEN_BLACK',   'A', 'FROG', '그린앤블랙다트프록',     'Green & Black Dart Frog',     'Dendrobates auratus',                 1100, true),
('DART_FROG_STRAWBERRY',    'A', 'FROG', '스트로베리다트프록',     'Strawberry Dart Frog',        'Oophaga pumilio',                     1200, true),
('BUMBLEBEE_DART_FROG',     'A', 'FROG', '범블비다트프록',         'Bumblebee Dart Frog',         'Dendrobates leucomelas',              1400, true),
('MANTELLA_GOLDEN',         'A', 'FROG', '골든만텔라',             'Golden Mantella',             'Mantella aurantiaca',                 1500, true),
('FIRE_BELLIED_TOAD',       'A', 'FROG', '파이어벨리토드',         'Fire-bellied Toad',           'Bombina orientalis',                  1600, true),
('BUDGETT_FROG',            'A', 'FROG', '버젯프록',               'Budgett''s Frog',             'Lepidobatrachus laevis',              1800, true),
('SURINAME_TOAD',           'A', 'FROG', '수리남토드',             'Suriname Toad',               'Pipa pipa',                           1900, true),
('ORNATE_HORNED_FROG',      'A', 'FROG', '오네이트혼드프록',       'Ornate Horned Frog',          'Ceratophrys ornata',                  2000, true),
('GREY_TREE_FROG',          'A', 'FROG', '그레이트리프록',         'Grey Tree Frog',              'Hyla versicolor',                     2200, true),
('CUBAN_TREE_FROG',         'A', 'FROG', '쿠반트리프록',           'Cuban Tree Frog',             'Osteopilus septentrionalis',          2300, true),
('AMERICAN_GREEN_TREE_FROG','A', 'FROG', '아메리칸그린트리프록',   'American Green Tree Frog',    'Hyla cinerea',                        2400, true),
('EUROPEAN_TREE_FROG',      'A', 'FROG', '유러피안트리프록',       'European Tree Frog',          'Hyla arborea',                        2500, true),

-- ═══════════════════════════════════════════════════════════════════════
--  양서류 (A)  ·  NEWT  9종
-- ═══════════════════════════════════════════════════════════════════════
('AXOLOTL',                    'A', 'NEWT', '액솔로틀',               'Axolotl',                      'Ambystoma mexicanum',        100,  true),
('EMPEROR_NEWT',               'A', 'NEWT', '엠페러뉴트',             'Emperor Newt',                 'Tylototriton shanjing',      200,  true),
('LAOS_NEWT',                  'A', 'NEWT', '라오스뉴트',             'Laos Warty Newt',              'Laotriton laoensis',         300,  true),
('FIRE_BELLIED_NEWT',          'A', 'NEWT', '파이어벨리뉴트',         'Chinese Fire-bellied Newt',    'Cynops orientalis',          400,  true),
('JAPANESE_FIRE_BELLIED_NEWT', 'A', 'NEWT', '재패니즈파이어벨리뉴트', 'Japanese Fire-bellied Newt',   'Cynops pyrrhogaster',        500,  true),
('SPANISH_RIBBED_NEWT',        'A', 'NEWT', '스페니쉬리브드뉴트',     'Spanish Ribbed Newt',          'Pleurodeles waltl',          600,  true),
('ALPINE_NEWT',                'A', 'NEWT', '알파인뉴트',             'Alpine Newt',                  'Ichthyosaura alpestris',     700,  true),
('TIGER_SALAMANDER',           'A', 'NEWT', '타이거샐러맨더',         'Tiger Salamander',             'Ambystoma tigrinum',         900,  true),
('FIRE_SALAMANDER',            'A', 'NEWT', '파이어샐러맨더',         'Fire Salamander',              'Salamandra salamandra',      1000, true)

ON CONFLICT (code) DO UPDATE SET
    category        = EXCLUDED.category,
    subcategory     = EXCLUDED.subcategory,
    name_ko         = EXCLUDED.name_ko,
    name_en         = EXCLUDED.name_en,
    scientific_name = EXCLUDED.scientific_name,
    display_order   = EXCLUDED.display_order,
    is_active       = EXCLUDED.is_active,
    updated_at      = NOW();

-- ─────────────────────────────────────────────────────────────────────────
-- v1 → v1.1 제거된 코드 비활성화 (FK 참조 보호, 하드 삭제 금지)
-- ─────────────────────────────────────────────────────────────────────────
UPDATE species_cd
   SET is_active  = false,
       updated_at = NOW()
 WHERE code IN (
     'MARBLED_NEWT',
     'CRANWELL_HORNED_FROG',
     'AFRICAN_CLAWED_FROG',
     'DART_FROG_DYEING',
     'RED_EARED_SLIDER',
     'INDIAN_STAR_TORTOISE',
     'TRANS_PECOS_RAT_SNAKE',
     'DUMERIL_BOA',
     'BOA_CONSTRICTOR',
     'OUSTALET_CHAMELEON',
     'FOUR_HORNED_CHAMELEON',
     'GIDGEE_SKINK',
     'TURNIP_TAILED_GECKO',
     'MOSSY_LEAF_TAILED_GECKO',
     'WESTERN_HOGNOSE_ALBINO',
     'EASTERN_HOGNOSE',
     'TAIWAN_BEAUTY_SNAKE'   -- v1.1에서 TAIWAN_BEAUTY_RAT_SNAKE 으로 코드 변경
 )
   AND is_active = true;
