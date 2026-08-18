-- =====================================================================
-- V1 — 베이스라인 스키마 (구 V1~V55 통합, 2026-08-19)
-- =====================================================================
--
-- 55개로 늘어난 마이그레이션을 하나로 합친 것이다. 내용은 "V55까지 전부 적용한
-- PostgreSQL 16 DB를 pg_dump 로 뽑은 최종 스키마"이므로, 순차 적용 결과와 동일하다.
-- (합친 뒤 빈 DB에 이 파일만 적용해 스키마를 다시 덤프하고 diff 로 검증했다)
--
-- 합친 이유: 신규 환경 기동 때마다 55단계를 순서대로 재생하는 비용, 그리고 중간
-- 단계에만 존재하다 사라진 테이블(alarm_mst, pet_photo_dtl, health_memo_dtl,
-- breeding_group, mating_rls ...)이 파일에 남아 현재 스키마를 읽기 어렵게 만드는 문제.
--
-- ⛔ 이미 구 이력(V1~V55)을 가진 DB에는 적용할 수 없다.
--    Flyway validate 가 V1 체크섬 불일치로 기동을 거부한다. 스쿼시는 운영 DB가
--    생기기 전에만 가능한 작업이고, 그래서 배포 직전인 지금 했다.
--    이후로 이 파일은 절대 수정하지 말 것 — 고치는 순간 모든 기존 DB가 깨진다.
--
-- 📎 구 V1~V55 원본은 git 이력에 남아 있다. 어떤 컬럼이 왜 생겼는지 추적할 때 참고:
--       git log --diff-filter=D --name-only -- 'bitpet_server/src/main/resources/db/migration/V*'
--
-- 다음 마이그레이션은 V2 부터 작성한다.
--
-- 이 파일 뒤에 R__01_species_cd_seed / R__02_morph_cd_seed 가 이어서 실행된다.
-- (종·모프 마스터는 여기 없음 — R__ 파일이 담당)
-- =====================================================================



-- pg_trgm  |  EXTENSION
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

-- EXTENSION pg_trgm  |  COMMENT
COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';

-- fn_bump_sync_version()  |  FUNCTION
CREATE FUNCTION fn_bump_sync_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.sync_version := nextval('sync_version_seq');
    RETURN NEW;
END;
$$;

-- admin_role_rls  |  TABLE
CREATE TABLE admin_role_rls (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying(20) NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    granted_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_admin_role_rls_role CHECK (((role)::text = ANY ((ARRAY['SUPER_ADMIN'::character varying, 'MODERATOR'::character varying])::text[])))
);

-- TABLE admin_role_rls  |  COMMENT
COMMENT ON TABLE admin_role_rls IS '관리자 권한 (user_type.GENERAL/BREEDER와 분리)';

-- COLUMN admin_role_rls.role  |  COMMENT
COMMENT ON COLUMN admin_role_rls.role IS 'SUPER_ADMIN / MODERATOR';

-- admin_role_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE admin_role_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- admin_role_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE admin_role_rls_id_seq OWNED BY admin_role_rls.id;

-- cleaning_dtl  |  TABLE
CREATE TABLE cleaning_dtl (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    cleaning_type character varying(20) NOT NULL,
    cleaned_at timestamp with time zone NOT NULL,
    memo text,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    routine_id bigint,
    created_by_user_id bigint,
    routine_log_id bigint,
    CONSTRAINT ck_cleaning_dtl_type CHECK (((cleaning_type)::text = ANY ((ARRAY['FULL'::character varying, 'PARTIAL'::character varying, 'WATER_CHANGE'::character varying])::text[])))
);

-- TABLE cleaning_dtl  |  COMMENT
COMMENT ON TABLE cleaning_dtl IS '청소 기록';

-- cleaning_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE cleaning_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- cleaning_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE cleaning_dtl_id_seq OWNED BY cleaning_dtl.id;

-- device_token_rls  |  TABLE
CREATE TABLE device_token_rls (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    device_token character varying(255) NOT NULL,
    platform character varying(10) NOT NULL,
    device_info character varying(255),
    last_used_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_device_token_platform CHECK (((platform)::text = ANY ((ARRAY['ANDROID'::character varying, 'IOS'::character varying])::text[])))
);

-- TABLE device_token_rls  |  COMMENT
COMMENT ON TABLE device_token_rls IS 'FCM/APNs 디바이스 토큰';

-- COLUMN device_token_rls.platform  |  COMMENT
COMMENT ON COLUMN device_token_rls.platform IS 'ANDROID / IOS';

-- device_token_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE device_token_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- device_token_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE device_token_rls_id_seq OWNED BY device_token_rls.id;

-- feeding_dtl  |  TABLE
CREATE TABLE feeding_dtl (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    food_type character varying(50),
    amount numeric(6,2),
    unit character varying(10),
    fed_at timestamp with time zone NOT NULL,
    memo text,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    routine_id bigint,
    size_label character varying(10),
    supplement character varying(20),
    created_by_user_id bigint,
    routine_log_id bigint,
    refused_yn character varying(1) DEFAULT 'N'::character varying NOT NULL,
    CONSTRAINT ck_feeding_dtl_food_type_by_refused CHECK (((((refused_yn)::text = 'Y'::text) AND (food_type IS NULL)) OR (((refused_yn)::text = 'N'::text) AND (food_type IS NOT NULL)))),
    CONSTRAINT ck_feeding_dtl_refused_yn CHECK (((refused_yn)::text = ANY ((ARRAY['Y'::character varying, 'N'::character varying])::text[]))),
    CONSTRAINT ck_feeding_dtl_supplement CHECK ((((supplement)::text = ANY ((ARRAY['CALCIUM'::character varying, 'PROBIOTIC'::character varying, 'VITAMIN'::character varying, 'OTHER'::character varying])::text[])) OR (supplement IS NULL)))
);

-- TABLE feeding_dtl  |  COMMENT
COMMENT ON TABLE feeding_dtl IS '급여 기록';

-- COLUMN feeding_dtl.routine_id  |  COMMENT
COMMENT ON COLUMN feeding_dtl.routine_id IS '연결된 루틴 (없으면 수동 기록)';

-- COLUMN feeding_dtl.size_label  |  COMMENT
COMMENT ON COLUMN feeding_dtl.size_label IS '먹이 크기 레이블 (XS/S/M/L/XL/XXL, 극소/소/중/대 등) — 프론트 관리';

-- COLUMN feeding_dtl.supplement  |  COMMENT
COMMENT ON COLUMN feeding_dtl.supplement IS '영양제: CALCIUM/PROBIOTIC/VITAMIN/OTHER (nullable)';

-- COLUMN feeding_dtl.refused_yn  |  COMMENT
COMMENT ON COLUMN feeding_dtl.refused_yn IS '거식 여부: Y=먹이 거부(food_type NULL, 메모만), N=일반 급여';

-- feeding_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE feeding_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- feeding_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE feeding_dtl_id_seq OWNED BY feeding_dtl.id;

-- memo_dtl  |  TABLE
CREATE TABLE memo_dtl (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    content text NOT NULL,
    logged_at timestamp with time zone NOT NULL,
    routine_id bigint,
    created_by_user_id bigint,
    routine_log_id bigint
);

-- TABLE memo_dtl  |  COMMENT
COMMENT ON TABLE memo_dtl IS '메모 기록 (health_memo_dtl 리네이밍, 태그 시스템 도입)';

-- health_memo_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE health_memo_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- health_memo_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE health_memo_dtl_id_seq OWNED BY memo_dtl.id;

-- laying_dtl  |  TABLE
CREATE TABLE laying_dtl (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    mating_id bigint,
    laid_at timestamp with time zone NOT NULL,
    egg_count_total integer NOT NULL,
    egg_count_fertile integer,
    incubation_temp numeric(4,1),
    incubation_humidity numeric(4,1),
    memo text,
    deleted_at timestamp with time zone,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id bigint,
    CONSTRAINT chk_laying_egg_total_positive CHECK ((egg_count_total > 0)),
    CONSTRAINT chk_laying_fertile_lte_total CHECK (((egg_count_fertile IS NULL) OR (egg_count_fertile <= egg_count_total))),
    CONSTRAINT chk_laying_fertile_non_negative CHECK (((egg_count_fertile IS NULL) OR (egg_count_fertile >= 0))),
    CONSTRAINT chk_laying_humidity_range CHECK (((incubation_humidity IS NULL) OR ((incubation_humidity >= (0)::numeric) AND (incubation_humidity <= (100)::numeric)))),
    CONSTRAINT chk_laying_temp_range CHECK (((incubation_temp IS NULL) OR ((incubation_temp >= (0)::numeric) AND (incubation_temp <= (50)::numeric))))
);

-- TABLE laying_dtl  |  COMMENT
COMMENT ON TABLE laying_dtl IS '산란(클러치) 기록 — 해칭은 laying_hatch_dtl 1:N';

-- COLUMN laying_dtl.mating_id  |  COMMENT
COMMENT ON COLUMN laying_dtl.mating_id IS '연관 메이팅 (선택) — mating 삭제 시 NULL SET';

-- laying_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE laying_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- laying_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE laying_dtl_id_seq OWNED BY laying_dtl.id;

-- laying_hatch_dtl  |  TABLE
CREATE TABLE laying_hatch_dtl (
    id bigint NOT NULL,
    laying_id bigint NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    hatched_at timestamp with time zone,
    hatched_pet_id bigint,
    memo text,
    deleted_at timestamp with time zone,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id bigint,
    CONSTRAINT chk_hatch_hatched_at CHECK ((((status)::text <> 'HATCHED'::text) OR (hatched_at IS NOT NULL))),
    CONSTRAINT chk_hatch_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'HATCHED'::character varying, 'FAILED'::character varying, 'SLUG'::character varying])::text[])))
);

-- TABLE laying_hatch_dtl  |  COMMENT
COMMENT ON TABLE laying_hatch_dtl IS '클러치별 해칭 추적 (PENDING/HATCHED/FAILED/SLUG)';

-- COLUMN laying_hatch_dtl.hatched_pet_id  |  COMMENT
COMMENT ON COLUMN laying_hatch_dtl.hatched_pet_id IS '해칭→개체 등록 시 pet_mst.id 연결, 자동 pet_relation_rls 생성';

-- laying_hatch_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE laying_hatch_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- laying_hatch_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE laying_hatch_dtl_id_seq OWNED BY laying_hatch_dtl.id;

-- mating_dtl  |  TABLE
CREATE TABLE mating_dtl (
    id bigint NOT NULL,
    male_pet_id bigint,
    female_pet_id bigint,
    memo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    external_partner_text character varying(255),
    duration_minutes integer,
    is_successful boolean,
    season_label character varying(20) NOT NULL,
    deleted_at timestamp with time zone,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    tried_at timestamp with time zone NOT NULL,
    created_by_user_id bigint,
    CONSTRAINT chk_mating_at_least_one_pet CHECK (((male_pet_id IS NOT NULL) OR (female_pet_id IS NOT NULL)))
);

-- TABLE mating_dtl  |  COMMENT
COMMENT ON TABLE mating_dtl IS '메이팅 기록 (기록 도메인 1급 카테고리로 승격, mating_rls에서 이동)';

-- COLUMN mating_dtl.external_partner_text  |  COMMENT
COMMENT ON COLUMN mating_dtl.external_partner_text IS '외부 개체 정보 자유 텍스트 (male/female 중 하나가 NULL일 때)';

-- COLUMN mating_dtl.is_successful  |  COMMENT
COMMENT ON COLUMN mating_dtl.is_successful IS 'NULL=미확인, TRUE=성공, FALSE=실패 — 산란 확인 후 업데이트';

-- mating_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE mating_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- mating_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE mating_rls_id_seq OWNED BY mating_dtl.id;

-- memo_tag_cd  |  TABLE
CREATE TABLE memo_tag_cd (
    id bigint NOT NULL,
    code character varying(30) NOT NULL,
    label_ko character varying(50) NOT NULL,
    label_en character varying(50),
    color_code character varying(7),
    display_order integer DEFAULT 0 NOT NULL,
    is_system boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- TABLE memo_tag_cd  |  COMMENT
COMMENT ON TABLE memo_tag_cd IS '메모 태그 코드 마스터 (enum 대신 코드 테이블, 사용자 정의 태그 확장 여지)';

-- COLUMN memo_tag_cd.is_system  |  COMMENT
COMMENT ON COLUMN memo_tag_cd.is_system IS 'TRUE이면 시스템 기본 태그 (삭제 불가)';

-- memo_tag_cd_id_seq  |  SEQUENCE
CREATE SEQUENCE memo_tag_cd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- memo_tag_cd_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE memo_tag_cd_id_seq OWNED BY memo_tag_cd.id;

-- memo_tag_rls  |  TABLE
CREATE TABLE memo_tag_rls (
    memo_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid
);

-- TABLE memo_tag_rls  |  COMMENT
COMMENT ON TABLE memo_tag_rls IS '메모↔태그 다대다 연결';

-- memo_vet_ext_dtl  |  TABLE
CREATE TABLE memo_vet_ext_dtl (
    memo_id bigint NOT NULL,
    clinic_name character varying(100),
    cost integer,
    next_visit_at timestamp with time zone,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_memo_vet_ext_cost CHECK (((cost IS NULL) OR (cost >= 0)))
);

-- TABLE memo_vet_ext_dtl  |  COMMENT
COMMENT ON TABLE memo_vet_ext_dtl IS '병원(VET) 태그 메모 확장 필드 (1:0..1)';

-- COLUMN memo_vet_ext_dtl.next_visit_at  |  COMMENT
COMMENT ON COLUMN memo_vet_ext_dtl.next_visit_at IS '다음 방문 예정일 — 알림 스케줄러용 인덱스 포함';

-- morph_cd  |  TABLE
CREATE TABLE morph_cd (
    id bigint NOT NULL,
    species_id bigint NOT NULL,
    name_ko character varying(100) NOT NULL,
    name_en character varying(100),
    display_order smallint DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    alias_list character varying(300),
    has_health_concern boolean DEFAULT false NOT NULL
);

-- TABLE morph_cd  |  COMMENT
COMMENT ON TABLE morph_cd IS '모프(색상변이) 코드 마스터';

-- morph_cd_id_seq  |  SEQUENCE
CREATE SEQUENCE morph_cd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- morph_cd_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE morph_cd_id_seq OWNED BY morph_cd.id;

-- nfc_tag_bind_hst  |  TABLE
CREATE TABLE nfc_tag_bind_hst (
    id bigint NOT NULL,
    tag_cd character varying(10) NOT NULL,
    action character varying(20) NOT NULL,
    pet_id bigint,
    prev_pet_id bigint,
    actor_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_nfc_tag_bind_hst_action CHECK (((action)::text = ANY ((ARRAY['BIND'::character varying, 'REBIND'::character varying, 'UNBIND'::character varying, 'REVOKE'::character varying])::text[])))
);

-- TABLE nfc_tag_bind_hst  |  COMMENT
COMMENT ON TABLE nfc_tag_bind_hst IS 'NFC 태그 연결 이력 (append-only). 태그 소유권 분쟁 판정 근거';

-- COLUMN nfc_tag_bind_hst.action  |  COMMENT
COMMENT ON COLUMN nfc_tag_bind_hst.action IS 'BIND 최초연결 / REBIND 다른 개체로 이전 / UNBIND 해제 / REVOKE 차단';

-- COLUMN nfc_tag_bind_hst.prev_pet_id  |  COMMENT
COMMENT ON COLUMN nfc_tag_bind_hst.prev_pet_id IS '이 액션 직전에 붙어 있던 개체. REBIND 분쟁의 핵심 값';

-- COLUMN nfc_tag_bind_hst.actor_id  |  COMMENT
COMMENT ON COLUMN nfc_tag_bind_hst.actor_id IS '액션 주체. 어드민 차단·탈퇴 정리처럼 사용자 행위가 아니면 NULL';

-- nfc_tag_bind_hst_id_seq  |  SEQUENCE
CREATE SEQUENCE nfc_tag_bind_hst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- nfc_tag_bind_hst_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE nfc_tag_bind_hst_id_seq OWNED BY nfc_tag_bind_hst.id;

-- nfc_tag_mst  |  TABLE
CREATE TABLE nfc_tag_mst (
    tag_cd character varying(10) NOT NULL,
    pet_id bigint,
    user_id bigint,
    linked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    chip_type character varying(20) DEFAULT 'NTAG203'::character varying NOT NULL,
    batch_no character varying(20),
    status character varying(20) DEFAULT 'STOCK'::character varying NOT NULL,
    CONSTRAINT ck_nfc_tag_mst_cd_format CHECK (((tag_cd)::text ~ '^[0-9A-HJKMNP-TV-Z]{6}$'::text)),
    CONSTRAINT ck_nfc_tag_mst_cd_upper CHECK (((tag_cd)::text = upper((tag_cd)::text))),
    CONSTRAINT ck_nfc_tag_mst_status CHECK (((status)::text = ANY ((ARRAY['STOCK'::character varying, 'SOLD'::character varying, 'BOUND'::character varying, 'REVOKED'::character varying])::text[])))
);

-- TABLE nfc_tag_mst  |  COMMENT
COMMENT ON TABLE nfc_tag_mst IS 'NFC 태그 이름표 — 태그코드와 개체의 연결';

-- COLUMN nfc_tag_mst.tag_cd  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.tag_cd IS '태그에 굽는 코드. 랜덤 6자(I/L/O/U 제외). 순차 부여 금지(주소 추측 방지)';

-- COLUMN nfc_tag_mst.pet_id  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.pet_id IS 'NULL = 미판매 재고 또는 연결 해제 상태';

-- COLUMN nfc_tag_mst.user_id  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.user_id IS '소유권. 남의 태그 탈취 방지용';

-- COLUMN nfc_tag_mst.linked_at  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.linked_at IS '최초 연결 시각. 해제해도 남겨 판매/미연결 구분에 사용';

-- COLUMN nfc_tag_mst.chip_type  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.chip_type IS '칩 세대. NTAG203은 패스워드 보호 불가(락 미적용 출고)';

-- COLUMN nfc_tag_mst.batch_no  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.batch_no IS '생산 배치. 불량 회수 단위';

-- COLUMN nfc_tag_mst.status  |  COMMENT
COMMENT ON COLUMN nfc_tag_mst.status IS 'STOCK=미판매 재고 / SOLD=판매됐으나 미연결 / BOUND=개체 연결됨 / REVOKED=분실·복제 사고로 영구 차단';

-- notification_log_dtl  |  TABLE
CREATE TABLE notification_log_dtl (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    pet_id bigint,
    routine_id bigint,
    template_code character varying(50),
    title character varying(255) NOT NULL,
    body text,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    pet_count integer,
    notification_type character varying(30) DEFAULT 'ROUTINE_ALARM'::character varying NOT NULL,
    reference_id bigint,
    CONSTRAINT ck_notification_log_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SENT'::character varying, 'FAILED'::character varying, 'READ'::character varying])::text[])))
);

-- TABLE notification_log_dtl  |  COMMENT
COMMENT ON TABLE notification_log_dtl IS '알림 발송 이력';

-- COLUMN notification_log_dtl.pet_id  |  COMMENT
COMMENT ON COLUMN notification_log_dtl.pet_id IS 'v2.4: 대표 개체 ID (다개체 알림 시 pet_id ASC LIMIT 1)';

-- COLUMN notification_log_dtl.status  |  COMMENT
COMMENT ON COLUMN notification_log_dtl.status IS 'PENDING / SENT / FAILED / READ';

-- COLUMN notification_log_dtl.pet_count  |  COMMENT
COMMENT ON COLUMN notification_log_dtl.pet_count IS '알림 발송 시점 연결 개체 수 (분석용)';

-- notification_log_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE notification_log_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- notification_log_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE notification_log_dtl_id_seq OWNED BY notification_log_dtl.id;

-- notification_template_cd  |  TABLE
CREATE TABLE notification_template_cd (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    title_template character varying(255) NOT NULL,
    body_template text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- TABLE notification_template_cd  |  COMMENT
COMMENT ON TABLE notification_template_cd IS '알림 템플릿 코드성 마스터';

-- notification_template_cd_id_seq  |  SEQUENCE
CREATE SEQUENCE notification_template_cd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- notification_template_cd_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE notification_template_cd_id_seq OWNED BY notification_template_cd.id;

-- pet_keeper_rls  |  TABLE
CREATE TABLE pet_keeper_rls (
    pet_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying(20) DEFAULT 'KEEPER'::character varying NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_pet_keeper_role CHECK (((role)::text = ANY ((ARRAY['OWNER'::character varying, 'KEEPER'::character varying])::text[])))
);

-- pet_morph_rls  |  TABLE
CREATE TABLE pet_morph_rls (
    pet_id bigint NOT NULL,
    morph_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid
);

-- pet_mst  |  TABLE
CREATE TABLE pet_mst (
    id bigint NOT NULL,
    serial_no character varying(8) NOT NULL,
    user_id bigint,
    name character varying(50) NOT NULL,
    gender character varying(10) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    species_id bigint,
    color_code character varying(7),
    breeding_date date,
    hatching_date date,
    adoption_date date,
    profile_photo_id bigint,
    deleted_at timestamp with time zone,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    description text,
    private_yn character varying(1) DEFAULT 'Y'::bpchar NOT NULL,
    hatching_date_precision character varying(5) DEFAULT 'DAY'::character varying,
    hatching_date_approximate boolean DEFAULT false NOT NULL,
    deceased_at date,
    is_orphaned boolean DEFAULT false NOT NULL,
    CONSTRAINT chk_pet_private_yn CHECK (((private_yn)::bpchar = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT ck_pet_mst_color_code CHECK (((color_code IS NULL) OR ((color_code)::text ~ '^#[0-9A-Fa-f]{6}$'::text))),
    CONSTRAINT ck_pet_mst_gender CHECK (((gender)::text = ANY ((ARRAY['MALE'::character varying, 'FEMALE'::character varying, 'UNKNOWN'::character varying])::text[]))),
    CONSTRAINT ck_pet_mst_serial_no CHECK (((length((serial_no)::text) >= 6) AND (length((serial_no)::text) <= 8)))
);

-- TABLE pet_mst  |  COMMENT
COMMENT ON TABLE pet_mst IS '개체 마스터 (v3 재구성)';

-- COLUMN pet_mst.serial_no  |  COMMENT
COMMENT ON COLUMN pet_mst.serial_no IS '외부 노출용 일련번호 VARCHAR(8), 6~8자리';

-- COLUMN pet_mst.user_id  |  COMMENT
COMMENT ON COLUMN pet_mst.user_id IS '소유자(표시용 비정규화). NULL = 탈퇴 익명화 개체 — 가계도에서 "정보 없음"으로 노출. 권한 판정은 pet_keeper_rls';

-- COLUMN pet_mst.species_id  |  COMMENT
COMMENT ON COLUMN pet_mst.species_id IS 'species_cd FK (NULL = 종 미지정, 시드 데이터 적재 후 NOT NULL 전환)';

-- COLUMN pet_mst.profile_photo_id  |  COMMENT
COMMENT ON COLUMN pet_mst.profile_photo_id IS 'pet_photo_dtl FK — V6 이후 FK 제약 추가';

-- COLUMN pet_mst.deleted_at  |  COMMENT
COMMENT ON COLUMN pet_mst.deleted_at IS 'Soft Delete 일시';

-- COLUMN pet_mst.is_orphaned  |  COMMENT
COMMENT ON COLUMN pet_mst.is_orphaned IS '탈퇴 익명화 개체. 신규 참조(부모 등록·메이팅 상대) 대상에서 제외되고, 참조가 0이 되면 정리 배치가 물리 삭제한다';

-- pet_relation_rls  |  TABLE
CREATE TABLE pet_relation_rls (
    id bigint NOT NULL,
    parent_pet_id bigint NOT NULL,
    child_pet_id bigint NOT NULL,
    relation_type character varying(10) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_pet_relation_type CHECK (((relation_type)::text = ANY ((ARRAY['FATHER'::character varying, 'MOTHER'::character varying])::text[])))
);

-- TABLE pet_relation_rls  |  COMMENT
COMMENT ON TABLE pet_relation_rls IS '부모-자식 관계';

-- COLUMN pet_relation_rls.relation_type  |  COMMENT
COMMENT ON COLUMN pet_relation_rls.relation_type IS 'FATHER / MOTHER';

-- pet_relation_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE pet_relation_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- pet_relation_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE pet_relation_rls_id_seq OWNED BY pet_relation_rls.id;

-- pet_share_invitation  |  TABLE
CREATE TABLE pet_share_invitation (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    inviter_user_id bigint NOT NULL,
    invitee_user_id bigint NOT NULL,
    invite_type character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    batch_id uuid NOT NULL,
    CONSTRAINT chk_pet_share_inv_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'ACCEPTED'::character varying, 'REJECTED'::character varying, 'CANCELED'::character varying, 'EXPIRED'::character varying])::text[]))),
    CONSTRAINT chk_pet_share_inv_type CHECK (((invite_type)::text = ANY ((ARRAY['SHARE'::character varying, 'TRANSFER'::character varying])::text[])))
);

-- pet_share_invitation_id_seq  |  SEQUENCE
CREATE SEQUENCE pet_share_invitation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- pet_share_invitation_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE pet_share_invitation_id_seq OWNED BY pet_share_invitation.id;

-- pets_id_seq  |  SEQUENCE
CREATE SEQUENCE pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- pets_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE pets_id_seq OWNED BY pet_mst.id;

-- photo_dtl  |  TABLE
CREATE TABLE photo_dtl (
    id bigint NOT NULL,
    entity_type character varying(20) NOT NULL,
    entity_id bigint NOT NULL,
    s3_key character varying(255) NOT NULL,
    file_size integer,
    mime_type character varying(50),
    width integer,
    height integer,
    display_order integer DEFAULT 0 NOT NULL,
    taken_at timestamp with time zone,
    caption text,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_photo_entity_type CHECK (((entity_type)::text = ANY ((ARRAY['PET'::character varying, 'MEMO'::character varying, 'MATING'::character varying, 'LAYING'::character varying])::text[])))
);

-- TABLE photo_dtl  |  COMMENT
COMMENT ON TABLE photo_dtl IS '폴리모픽 사진 테이블 (PET/MEMO/MATING/LAYING) — DB FK 없이 서비스 레이어에서 참조 무결성 관리';

-- COLUMN photo_dtl.entity_type  |  COMMENT
COMMENT ON COLUMN photo_dtl.entity_type IS 'PET | MEMO | MATING | LAYING';

-- COLUMN photo_dtl.entity_id  |  COMMENT
COMMENT ON COLUMN photo_dtl.entity_id IS '대상 엔티티 PK (폴리모픽 → DB FK 미설정)';

-- photo_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE photo_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- photo_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE photo_dtl_id_seq OWNED BY photo_dtl.id;

-- post_category_cd  |  TABLE
CREATE TABLE post_category_cd (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name_ko character varying(50) NOT NULL,
    description text,
    display_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- post_category_cd_id_seq  |  SEQUENCE
CREATE SEQUENCE post_category_cd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- post_category_cd_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE post_category_cd_id_seq OWNED BY post_category_cd.id;

-- post_comment_dtl  |  TABLE
CREATE TABLE post_comment_dtl (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    user_id bigint NOT NULL,
    parent_comment_id bigint,
    content text NOT NULL,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid
);

-- TABLE post_comment_dtl  |  COMMENT
COMMENT ON TABLE post_comment_dtl IS '댓글 (1단계 대댓글 지원)';

-- COLUMN post_comment_dtl.parent_comment_id  |  COMMENT
COMMENT ON COLUMN post_comment_dtl.parent_comment_id IS 'NULL이면 최상위 댓글, NOT NULL이면 대댓글';

-- post_comment_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE post_comment_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- post_comment_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE post_comment_dtl_id_seq OWNED BY post_comment_dtl.id;

-- post_like_rls  |  TABLE
CREATE TABLE post_like_rls (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid
);

-- TABLE post_like_rls  |  COMMENT
COMMENT ON TABLE post_like_rls IS '좋아요 (스키마 구축, MVP 공개 여부 추후 결정)';

-- post_like_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE post_like_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- post_like_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE post_like_rls_id_seq OWNED BY post_like_rls.id;

-- post_mst  |  TABLE
CREATE TABLE post_mst (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    category_id bigint NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    view_count integer DEFAULT 0 NOT NULL,
    like_count integer DEFAULT 0 NOT NULL,
    comment_count integer DEFAULT 0 NOT NULL,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    pinned_yn character varying(1) DEFAULT 'N'::character varying NOT NULL
);

-- TABLE post_mst  |  COMMENT
COMMENT ON TABLE post_mst IS '게시글';

-- COLUMN post_mst.like_count  |  COMMENT
COMMENT ON COLUMN post_mst.like_count IS 'Redis INCR 기반 집계 + 주기적 reconciliation';

-- COLUMN post_mst.deleted_at  |  COMMENT
COMMENT ON COLUMN post_mst.deleted_at IS 'Soft Delete';

-- COLUMN post_mst.pinned_yn  |  COMMENT
COMMENT ON COLUMN post_mst.pinned_yn IS '공지 상단 고정 여부 Y/N (관리자만 설정)';

-- post_mst_id_seq  |  SEQUENCE
CREATE SEQUENCE post_mst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- post_mst_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE post_mst_id_seq OWNED BY post_mst.id;

-- post_photo_dtl  |  TABLE
CREATE TABLE post_photo_dtl (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    s3_key character varying(255) NOT NULL,
    display_order integer DEFAULT 0 NOT NULL,
    width integer,
    height integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- TABLE post_photo_dtl  |  COMMENT
COMMENT ON TABLE post_photo_dtl IS '게시글 이미지 (장당 최대 5장은 앱 레벨 검증)';

-- post_photo_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE post_photo_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- post_photo_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE post_photo_dtl_id_seq OWNED BY post_photo_dtl.id;

-- routine_log_dtl  |  TABLE
CREATE TABLE routine_log_dtl (
    id bigint NOT NULL,
    routine_id bigint NOT NULL,
    pet_id bigint NOT NULL,
    status character varying(20) DEFAULT 'COMPLETED'::character varying NOT NULL,
    executed_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id bigint,
    CONSTRAINT ck_routine_log_dtl_status CHECK (((status)::text = ANY ((ARRAY['COMPLETED'::character varying, 'REFUSED'::character varying])::text[])))
);

-- TABLE routine_log_dtl  |  COMMENT
COMMENT ON TABLE routine_log_dtl IS '루틴 실행 기록 (v2.3+). FEEDING은 feeding_dtl에 기록.';

-- COLUMN routine_log_dtl.status  |  COMMENT
COMMENT ON COLUMN routine_log_dtl.status IS 'COMPLETED: 완료, REFUSED: 명시적 미수행+메모';

-- routine_log_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE routine_log_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- routine_log_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE routine_log_dtl_id_seq OWNED BY routine_log_dtl.id;

-- routine_mst  |  TABLE
CREATE TABLE routine_mst (
    id bigint NOT NULL,
    routine_type character varying(20) NOT NULL,
    title character varying(100) NOT NULL,
    cycle_days integer NOT NULL,
    last_executed_at date,
    next_due_at date,
    is_active boolean DEFAULT true NOT NULL,
    memo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id bigint NOT NULL,
    alarm_time time without time zone,
    is_alarm_enabled boolean DEFAULT false NOT NULL,
    last_notified_at timestamp with time zone,
    start_date date,
    deleted_at timestamp with time zone,
    CONSTRAINT ck_routine_mst_cycle CHECK ((cycle_days > 0)),
    CONSTRAINT ck_routine_mst_type CHECK (((routine_type)::text = ANY ((ARRAY['FEEDING'::character varying, 'CLEANING'::character varying, 'WEIGHT'::character varying, 'CUSTOM'::character varying])::text[])))
);

-- TABLE routine_mst  |  COMMENT
COMMENT ON TABLE routine_mst IS '루틴 (UNIQUE 제약 없음 — 다중 주기 허용)';

-- COLUMN routine_mst.cycle_days  |  COMMENT
COMMENT ON COLUMN routine_mst.cycle_days IS '주기 (일 단위, 양수)';

-- COLUMN routine_mst.next_due_at  |  COMMENT
COMMENT ON COLUMN routine_mst.next_due_at IS '다음 예정 시각 (스케줄러 파생)';

-- COLUMN routine_mst.user_id  |  COMMENT
COMMENT ON COLUMN routine_mst.user_id IS '루틴 소유자 (v2.4: pet_id 에서 변경)';

-- COLUMN routine_mst.alarm_time  |  COMMENT
COMMENT ON COLUMN routine_mst.alarm_time IS '알림 시각 (v2.1: alarm_mst 통합)';

-- COLUMN routine_mst.is_alarm_enabled  |  COMMENT
COMMENT ON COLUMN routine_mst.is_alarm_enabled IS '알림 켜기/끄기';

-- COLUMN routine_mst.start_date  |  COMMENT
COMMENT ON COLUMN routine_mst.start_date IS 'v6: 루틴 시작일(고정). nextDueAt 초기값과 동일하나 완료해도 불변 — 캘린더 표시 하한';

-- COLUMN routine_mst.deleted_at  |  COMMENT
COMMENT ON COLUMN routine_mst.deleted_at IS 'soft delete 시각 (NULL = 활성). 삭제해도 기록 테이블은 보존';

-- routine_mst_id_seq  |  SEQUENCE
CREATE SEQUENCE routine_mst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- routine_mst_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE routine_mst_id_seq OWNED BY routine_mst.id;

-- routine_pet_rls  |  TABLE
CREATE TABLE routine_pet_rls (
    id bigint NOT NULL,
    routine_id bigint NOT NULL,
    pet_id bigint NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- TABLE routine_pet_rls  |  COMMENT
COMMENT ON TABLE routine_pet_rls IS '루틴-개체 다대다 연결 (v2.4 신규)';

-- routine_pet_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE routine_pet_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- routine_pet_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE routine_pet_rls_id_seq OWNED BY routine_pet_rls.id;

-- s3_delete_queue_dtl  |  TABLE
CREATE TABLE s3_delete_queue_dtl (
    id bigint NOT NULL,
    s3_key character varying(255) NOT NULL,
    attempt_cnt integer DEFAULT 0 NOT NULL,
    last_error text,
    succeeded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- TABLE s3_delete_queue_dtl  |  COMMENT
COMMENT ON TABLE s3_delete_queue_dtl IS 'S3 오브젝트 삭제 재시도 큐 (탈퇴·개체 정리에서 적재)';

-- COLUMN s3_delete_queue_dtl.attempt_cnt  |  COMMENT
COMMENT ON COLUMN s3_delete_queue_dtl.attempt_cnt IS '시도 횟수. 한계치를 넘기면 배치가 손대지 않고 수동 확인 대상으로 남긴다';

-- s3_delete_queue_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE s3_delete_queue_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- s3_delete_queue_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE s3_delete_queue_dtl_id_seq OWNED BY s3_delete_queue_dtl.id;

-- serial_pool_stat_mst  |  TABLE
CREATE TABLE serial_pool_stat_mst (
    id bigint NOT NULL,
    serial_length integer NOT NULL,
    total_capacity bigint NOT NULL,
    used_count bigint DEFAULT 0 NOT NULL,
    usage_rate numeric(5,4) DEFAULT 0 NOT NULL,
    is_current boolean DEFAULT false NOT NULL,
    expanded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- TABLE serial_pool_stat_mst  |  COMMENT
COMMENT ON TABLE serial_pool_stat_mst IS '일련번호 풀 사용량 통계 (Scheduler 일 1회 갱신)';

-- COLUMN serial_pool_stat_mst.is_current  |  COMMENT
COMMENT ON COLUMN serial_pool_stat_mst.is_current IS '현재 발급에 사용 중인 길이';

-- COLUMN serial_pool_stat_mst.expanded_at  |  COMMENT
COMMENT ON COLUMN serial_pool_stat_mst.expanded_at IS '80% 도달로 확장된 시각';

-- serial_pool_stat_mst_id_seq  |  SEQUENCE
CREATE SEQUENCE serial_pool_stat_mst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- serial_pool_stat_mst_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE serial_pool_stat_mst_id_seq OWNED BY serial_pool_stat_mst.id;

-- species_cd  |  TABLE
CREATE TABLE species_cd (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    category character(2) NOT NULL,
    subcategory character varying(20),
    name_ko character varying(100) NOT NULL,
    name_en character varying(100),
    scientific_name character varying(150),
    display_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_species_cd_category CHECK ((category = ANY (ARRAY['R'::bpchar, 'A'::bpchar])))
);

-- TABLE species_cd  |  COMMENT
COMMENT ON TABLE species_cd IS '종 마스터 (배포 없이 종 추가 가능)';

-- COLUMN species_cd.code  |  COMMENT
COMMENT ON COLUMN species_cd.code IS 'LEOPARD_GECKO 등 시스템 코드';

-- COLUMN species_cd.category  |  COMMENT
COMMENT ON COLUMN species_cd.category IS 'REPTILE / AMPHIBIAN';

-- COLUMN species_cd.subcategory  |  COMMENT
COMMENT ON COLUMN species_cd.subcategory IS 'LIZARD / GECKO / IGUANA / TURTLE / SNAKE / FROG 등';

-- species_cd_id_seq  |  SEQUENCE
CREATE SEQUENCE species_cd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- species_cd_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE species_cd_id_seq OWNED BY species_cd.id;

-- sync_version_seq  |  SEQUENCE
CREATE SEQUENCE sync_version_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- user_mst  |  TABLE
CREATE TABLE user_mst (
    id bigint NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(50) NOT NULL,
    profile_image_url text,
    user_type character varying(20) DEFAULT 'GENERAL'::character varying NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    share_code character varying(8),
    show_nickname_in_pedigree boolean DEFAULT true NOT NULL
);

-- TABLE user_mst  |  COMMENT
COMMENT ON TABLE user_mst IS '사용자 마스터';

-- COLUMN user_mst.email  |  COMMENT
COMMENT ON COLUMN user_mst.email IS '로그인 이메일 (UNIQUE)';

-- COLUMN user_mst.password_hash  |  COMMENT
COMMENT ON COLUMN user_mst.password_hash IS 'bcrypt 해시';

-- COLUMN user_mst.name  |  COMMENT
COMMENT ON COLUMN user_mst.name IS '표시 이름';

-- COLUMN user_mst.user_type  |  COMMENT
COMMENT ON COLUMN user_mst.user_type IS 'GENERAL / BREEDER (ADMIN은 admin_role_rls로 분리)';

-- COLUMN user_mst.last_login_at  |  COMMENT
COMMENT ON COLUMN user_mst.last_login_at IS '최근 로그인 일시';

-- COLUMN user_mst.deleted_at  |  COMMENT
COMMENT ON COLUMN user_mst.deleted_at IS 'Soft Delete 일시 (NULL이면 활성)';

-- COLUMN user_mst.share_code  |  COMMENT
COMMENT ON COLUMN user_mst.share_code IS '개체 공유/입분양 대상 식별 코드 (전역 유일). 마이페이지에서 확인';

-- COLUMN user_mst.show_nickname_in_pedigree  |  COMMENT
COMMENT ON COLUMN user_mst.show_nickname_in_pedigree IS '가계도/개체 카드에 내 닉네임을 노출할지. false 면 "비공개"로 치환되고 프로필 이동 불가';

-- user_mst_id_seq  |  SEQUENCE
CREATE SEQUENCE user_mst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- user_mst_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE user_mst_id_seq OWNED BY user_mst.id;

-- user_oauth_rls  |  TABLE
CREATE TABLE user_oauth_rls (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    provider character varying(20) NOT NULL,
    provider_user_id character varying(255) NOT NULL,
    provider_email character varying(255),
    access_token text,
    refresh_token text,
    token_expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_user_oauth_rls_provider CHECK (((provider)::text = ANY ((ARRAY['GOOGLE'::character varying, 'KAKAO'::character varying, 'NAVER'::character varying])::text[])))
);

-- TABLE user_oauth_rls  |  COMMENT
COMMENT ON TABLE user_oauth_rls IS '사용자-OAuth 공급자 연결';

-- COLUMN user_oauth_rls.provider  |  COMMENT
COMMENT ON COLUMN user_oauth_rls.provider IS 'GOOGLE / KAKAO / NAVER';

-- COLUMN user_oauth_rls.provider_user_id  |  COMMENT
COMMENT ON COLUMN user_oauth_rls.provider_user_id IS '공급자측 식별자 (sub 등)';

-- user_oauth_rls_id_seq  |  SEQUENCE
CREATE SEQUENCE user_oauth_rls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- user_oauth_rls_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE user_oauth_rls_id_seq OWNED BY user_oauth_rls.id;

-- weight_dtl  |  TABLE
CREATE TABLE weight_dtl (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    weight_g numeric(8,2) NOT NULL,
    measured_at timestamp with time zone NOT NULL,
    source character varying(20) DEFAULT 'MANUAL'::character varying NOT NULL,
    memo text,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    client_id character varying(64),
    client_change_id uuid,
    routine_id bigint,
    created_by_user_id bigint,
    routine_log_id bigint,
    CONSTRAINT ck_weight_dtl_source CHECK (((source)::text = ANY ((ARRAY['MANUAL'::character varying, 'BLUETOOTH'::character varying])::text[])))
);

-- TABLE weight_dtl  |  COMMENT
COMMENT ON TABLE weight_dtl IS '체중 기록';

-- COLUMN weight_dtl.source  |  COMMENT
COMMENT ON COLUMN weight_dtl.source IS 'MANUAL / BLUETOOTH (2차)';

-- weight_dtl_id_seq  |  SEQUENCE
CREATE SEQUENCE weight_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- weight_dtl_id_seq  |  SEQUENCE OWNED BY
ALTER SEQUENCE weight_dtl_id_seq OWNED BY weight_dtl.id;

-- admin_role_rls id  |  DEFAULT
ALTER TABLE ONLY admin_role_rls ALTER COLUMN id SET DEFAULT nextval('admin_role_rls_id_seq'::regclass);

-- cleaning_dtl id  |  DEFAULT
ALTER TABLE ONLY cleaning_dtl ALTER COLUMN id SET DEFAULT nextval('cleaning_dtl_id_seq'::regclass);

-- device_token_rls id  |  DEFAULT
ALTER TABLE ONLY device_token_rls ALTER COLUMN id SET DEFAULT nextval('device_token_rls_id_seq'::regclass);

-- feeding_dtl id  |  DEFAULT
ALTER TABLE ONLY feeding_dtl ALTER COLUMN id SET DEFAULT nextval('feeding_dtl_id_seq'::regclass);

-- laying_dtl id  |  DEFAULT
ALTER TABLE ONLY laying_dtl ALTER COLUMN id SET DEFAULT nextval('laying_dtl_id_seq'::regclass);

-- laying_hatch_dtl id  |  DEFAULT
ALTER TABLE ONLY laying_hatch_dtl ALTER COLUMN id SET DEFAULT nextval('laying_hatch_dtl_id_seq'::regclass);

-- mating_dtl id  |  DEFAULT
ALTER TABLE ONLY mating_dtl ALTER COLUMN id SET DEFAULT nextval('mating_rls_id_seq'::regclass);

-- memo_dtl id  |  DEFAULT
ALTER TABLE ONLY memo_dtl ALTER COLUMN id SET DEFAULT nextval('health_memo_dtl_id_seq'::regclass);

-- memo_tag_cd id  |  DEFAULT
ALTER TABLE ONLY memo_tag_cd ALTER COLUMN id SET DEFAULT nextval('memo_tag_cd_id_seq'::regclass);

-- morph_cd id  |  DEFAULT
ALTER TABLE ONLY morph_cd ALTER COLUMN id SET DEFAULT nextval('morph_cd_id_seq'::regclass);

-- nfc_tag_bind_hst id  |  DEFAULT
ALTER TABLE ONLY nfc_tag_bind_hst ALTER COLUMN id SET DEFAULT nextval('nfc_tag_bind_hst_id_seq'::regclass);

-- notification_log_dtl id  |  DEFAULT
ALTER TABLE ONLY notification_log_dtl ALTER COLUMN id SET DEFAULT nextval('notification_log_dtl_id_seq'::regclass);

-- notification_template_cd id  |  DEFAULT
ALTER TABLE ONLY notification_template_cd ALTER COLUMN id SET DEFAULT nextval('notification_template_cd_id_seq'::regclass);

-- pet_mst id  |  DEFAULT
ALTER TABLE ONLY pet_mst ALTER COLUMN id SET DEFAULT nextval('pets_id_seq'::regclass);

-- pet_relation_rls id  |  DEFAULT
ALTER TABLE ONLY pet_relation_rls ALTER COLUMN id SET DEFAULT nextval('pet_relation_rls_id_seq'::regclass);

-- pet_share_invitation id  |  DEFAULT
ALTER TABLE ONLY pet_share_invitation ALTER COLUMN id SET DEFAULT nextval('pet_share_invitation_id_seq'::regclass);

-- photo_dtl id  |  DEFAULT
ALTER TABLE ONLY photo_dtl ALTER COLUMN id SET DEFAULT nextval('photo_dtl_id_seq'::regclass);

-- post_category_cd id  |  DEFAULT
ALTER TABLE ONLY post_category_cd ALTER COLUMN id SET DEFAULT nextval('post_category_cd_id_seq'::regclass);

-- post_comment_dtl id  |  DEFAULT
ALTER TABLE ONLY post_comment_dtl ALTER COLUMN id SET DEFAULT nextval('post_comment_dtl_id_seq'::regclass);

-- post_like_rls id  |  DEFAULT
ALTER TABLE ONLY post_like_rls ALTER COLUMN id SET DEFAULT nextval('post_like_rls_id_seq'::regclass);

-- post_mst id  |  DEFAULT
ALTER TABLE ONLY post_mst ALTER COLUMN id SET DEFAULT nextval('post_mst_id_seq'::regclass);

-- post_photo_dtl id  |  DEFAULT
ALTER TABLE ONLY post_photo_dtl ALTER COLUMN id SET DEFAULT nextval('post_photo_dtl_id_seq'::regclass);

-- routine_log_dtl id  |  DEFAULT
ALTER TABLE ONLY routine_log_dtl ALTER COLUMN id SET DEFAULT nextval('routine_log_dtl_id_seq'::regclass);

-- routine_mst id  |  DEFAULT
ALTER TABLE ONLY routine_mst ALTER COLUMN id SET DEFAULT nextval('routine_mst_id_seq'::regclass);

-- routine_pet_rls id  |  DEFAULT
ALTER TABLE ONLY routine_pet_rls ALTER COLUMN id SET DEFAULT nextval('routine_pet_rls_id_seq'::regclass);

-- s3_delete_queue_dtl id  |  DEFAULT
ALTER TABLE ONLY s3_delete_queue_dtl ALTER COLUMN id SET DEFAULT nextval('s3_delete_queue_dtl_id_seq'::regclass);

-- serial_pool_stat_mst id  |  DEFAULT
ALTER TABLE ONLY serial_pool_stat_mst ALTER COLUMN id SET DEFAULT nextval('serial_pool_stat_mst_id_seq'::regclass);

-- species_cd id  |  DEFAULT
ALTER TABLE ONLY species_cd ALTER COLUMN id SET DEFAULT nextval('species_cd_id_seq'::regclass);

-- user_mst id  |  DEFAULT
ALTER TABLE ONLY user_mst ALTER COLUMN id SET DEFAULT nextval('user_mst_id_seq'::regclass);

-- user_oauth_rls id  |  DEFAULT
ALTER TABLE ONLY user_oauth_rls ALTER COLUMN id SET DEFAULT nextval('user_oauth_rls_id_seq'::regclass);

-- weight_dtl id  |  DEFAULT
ALTER TABLE ONLY weight_dtl ALTER COLUMN id SET DEFAULT nextval('weight_dtl_id_seq'::regclass);

-- admin_role_rls admin_role_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY admin_role_rls
    ADD CONSTRAINT admin_role_rls_pkey PRIMARY KEY (id);

-- cleaning_dtl cleaning_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY cleaning_dtl
    ADD CONSTRAINT cleaning_dtl_pkey PRIMARY KEY (id);

-- device_token_rls device_token_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY device_token_rls
    ADD CONSTRAINT device_token_rls_pkey PRIMARY KEY (id);

-- feeding_dtl feeding_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY feeding_dtl
    ADD CONSTRAINT feeding_dtl_pkey PRIMARY KEY (id);

-- memo_dtl health_memo_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY memo_dtl
    ADD CONSTRAINT health_memo_dtl_pkey PRIMARY KEY (id);

-- laying_dtl laying_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY laying_dtl
    ADD CONSTRAINT laying_dtl_pkey PRIMARY KEY (id);

-- laying_hatch_dtl laying_hatch_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY laying_hatch_dtl
    ADD CONSTRAINT laying_hatch_dtl_pkey PRIMARY KEY (id);

-- mating_dtl mating_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY mating_dtl
    ADD CONSTRAINT mating_rls_pkey PRIMARY KEY (id);

-- memo_tag_cd memo_tag_cd_pkey  |  CONSTRAINT
ALTER TABLE ONLY memo_tag_cd
    ADD CONSTRAINT memo_tag_cd_pkey PRIMARY KEY (id);

-- memo_tag_rls memo_tag_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY memo_tag_rls
    ADD CONSTRAINT memo_tag_rls_pkey PRIMARY KEY (memo_id, tag_id);

-- memo_vet_ext_dtl memo_vet_ext_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY memo_vet_ext_dtl
    ADD CONSTRAINT memo_vet_ext_dtl_pkey PRIMARY KEY (memo_id);

-- morph_cd morph_cd_pkey  |  CONSTRAINT
ALTER TABLE ONLY morph_cd
    ADD CONSTRAINT morph_cd_pkey PRIMARY KEY (id);

-- nfc_tag_bind_hst nfc_tag_bind_hst_pkey  |  CONSTRAINT
ALTER TABLE ONLY nfc_tag_bind_hst
    ADD CONSTRAINT nfc_tag_bind_hst_pkey PRIMARY KEY (id);

-- nfc_tag_mst nfc_tag_mst_pkey  |  CONSTRAINT
ALTER TABLE ONLY nfc_tag_mst
    ADD CONSTRAINT nfc_tag_mst_pkey PRIMARY KEY (tag_cd);

-- notification_log_dtl notification_log_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY notification_log_dtl
    ADD CONSTRAINT notification_log_dtl_pkey PRIMARY KEY (id);

-- notification_template_cd notification_template_cd_pkey  |  CONSTRAINT
ALTER TABLE ONLY notification_template_cd
    ADD CONSTRAINT notification_template_cd_pkey PRIMARY KEY (id);

-- pet_relation_rls pet_relation_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY pet_relation_rls
    ADD CONSTRAINT pet_relation_rls_pkey PRIMARY KEY (id);

-- pet_share_invitation pet_share_invitation_pkey  |  CONSTRAINT
ALTER TABLE ONLY pet_share_invitation
    ADD CONSTRAINT pet_share_invitation_pkey PRIMARY KEY (id);

-- pet_mst pets_pkey  |  CONSTRAINT
ALTER TABLE ONLY pet_mst
    ADD CONSTRAINT pets_pkey PRIMARY KEY (id);

-- photo_dtl photo_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY photo_dtl
    ADD CONSTRAINT photo_dtl_pkey PRIMARY KEY (id);

-- pet_keeper_rls pk_pet_keeper  |  CONSTRAINT
ALTER TABLE ONLY pet_keeper_rls
    ADD CONSTRAINT pk_pet_keeper PRIMARY KEY (pet_id, user_id);

-- pet_morph_rls pk_pet_morph_rls  |  CONSTRAINT
ALTER TABLE ONLY pet_morph_rls
    ADD CONSTRAINT pk_pet_morph_rls PRIMARY KEY (pet_id, morph_id);

-- post_category_cd post_category_cd_pkey  |  CONSTRAINT
ALTER TABLE ONLY post_category_cd
    ADD CONSTRAINT post_category_cd_pkey PRIMARY KEY (id);

-- post_comment_dtl post_comment_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY post_comment_dtl
    ADD CONSTRAINT post_comment_dtl_pkey PRIMARY KEY (id);

-- post_like_rls post_like_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY post_like_rls
    ADD CONSTRAINT post_like_rls_pkey PRIMARY KEY (id);

-- post_mst post_mst_pkey  |  CONSTRAINT
ALTER TABLE ONLY post_mst
    ADD CONSTRAINT post_mst_pkey PRIMARY KEY (id);

-- post_photo_dtl post_photo_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY post_photo_dtl
    ADD CONSTRAINT post_photo_dtl_pkey PRIMARY KEY (id);

-- routine_log_dtl routine_log_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY routine_log_dtl
    ADD CONSTRAINT routine_log_dtl_pkey PRIMARY KEY (id);

-- routine_mst routine_mst_pkey  |  CONSTRAINT
ALTER TABLE ONLY routine_mst
    ADD CONSTRAINT routine_mst_pkey PRIMARY KEY (id);

-- routine_pet_rls routine_pet_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY routine_pet_rls
    ADD CONSTRAINT routine_pet_rls_pkey PRIMARY KEY (id);

-- s3_delete_queue_dtl s3_delete_queue_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY s3_delete_queue_dtl
    ADD CONSTRAINT s3_delete_queue_dtl_pkey PRIMARY KEY (id);

-- serial_pool_stat_mst serial_pool_stat_mst_pkey  |  CONSTRAINT
ALTER TABLE ONLY serial_pool_stat_mst
    ADD CONSTRAINT serial_pool_stat_mst_pkey PRIMARY KEY (id);

-- species_cd species_cd_pkey  |  CONSTRAINT
ALTER TABLE ONLY species_cd
    ADD CONSTRAINT species_cd_pkey PRIMARY KEY (id);

-- admin_role_rls uk_admin_role_rls  |  CONSTRAINT
ALTER TABLE ONLY admin_role_rls
    ADD CONSTRAINT uk_admin_role_rls UNIQUE (user_id, role);

-- cleaning_dtl uk_cleaning_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY cleaning_dtl
    ADD CONSTRAINT uk_cleaning_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- device_token_rls uk_device_token_rls  |  CONSTRAINT
ALTER TABLE ONLY device_token_rls
    ADD CONSTRAINT uk_device_token_rls UNIQUE (device_token);

-- feeding_dtl uk_feeding_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY feeding_dtl
    ADD CONSTRAINT uk_feeding_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- laying_hatch_dtl uk_hatch_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY laying_hatch_dtl
    ADD CONSTRAINT uk_hatch_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- laying_dtl uk_laying_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY laying_dtl
    ADD CONSTRAINT uk_laying_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- mating_dtl uk_mating_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY mating_dtl
    ADD CONSTRAINT uk_mating_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- memo_dtl uk_memo_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY memo_dtl
    ADD CONSTRAINT uk_memo_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- memo_tag_rls uk_memo_tag_rls_sync  |  CONSTRAINT
ALTER TABLE ONLY memo_tag_rls
    ADD CONSTRAINT uk_memo_tag_rls_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- memo_vet_ext_dtl uk_memo_vet_ext_sync  |  CONSTRAINT
ALTER TABLE ONLY memo_vet_ext_dtl
    ADD CONSTRAINT uk_memo_vet_ext_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- notification_template_cd uk_notification_template_cd_code  |  CONSTRAINT
ALTER TABLE ONLY notification_template_cd
    ADD CONSTRAINT uk_notification_template_cd_code UNIQUE (code);

-- pet_mst uk_pet_mst_sync  |  CONSTRAINT
ALTER TABLE ONLY pet_mst
    ADD CONSTRAINT uk_pet_mst_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- pet_relation_rls uk_pet_relation  |  CONSTRAINT
ALTER TABLE ONLY pet_relation_rls
    ADD CONSTRAINT uk_pet_relation UNIQUE (parent_pet_id, child_pet_id, relation_type);

-- post_category_cd uk_post_category_cd_code  |  CONSTRAINT
ALTER TABLE ONLY post_category_cd
    ADD CONSTRAINT uk_post_category_cd_code UNIQUE (code);

-- post_comment_dtl uk_post_comment_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY post_comment_dtl
    ADD CONSTRAINT uk_post_comment_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- post_like_rls uk_post_like_rls  |  CONSTRAINT
ALTER TABLE ONLY post_like_rls
    ADD CONSTRAINT uk_post_like_rls UNIQUE (post_id, user_id);

-- post_like_rls uk_post_like_rls_sync  |  CONSTRAINT
ALTER TABLE ONLY post_like_rls
    ADD CONSTRAINT uk_post_like_rls_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- post_mst uk_post_mst_sync  |  CONSTRAINT
ALTER TABLE ONLY post_mst
    ADD CONSTRAINT uk_post_mst_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- serial_pool_stat_mst uk_serial_pool_stat_length  |  CONSTRAINT
ALTER TABLE ONLY serial_pool_stat_mst
    ADD CONSTRAINT uk_serial_pool_stat_length UNIQUE (serial_length);

-- species_cd uk_species_cd_code  |  CONSTRAINT
ALTER TABLE ONLY species_cd
    ADD CONSTRAINT uk_species_cd_code UNIQUE (code);

-- user_oauth_rls uk_user_oauth_rls_provider_user  |  CONSTRAINT
ALTER TABLE ONLY user_oauth_rls
    ADD CONSTRAINT uk_user_oauth_rls_provider_user UNIQUE (provider, provider_user_id);

-- weight_dtl uk_weight_dtl_sync  |  CONSTRAINT
ALTER TABLE ONLY weight_dtl
    ADD CONSTRAINT uk_weight_dtl_sync UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- memo_tag_cd uq_memo_tag_cd_code  |  CONSTRAINT
ALTER TABLE ONLY memo_tag_cd
    ADD CONSTRAINT uq_memo_tag_cd_code UNIQUE (code);

-- morph_cd uq_morph_cd_species_name_ko  |  CONSTRAINT
ALTER TABLE ONLY morph_cd
    ADD CONSTRAINT uq_morph_cd_species_name_ko UNIQUE (species_id, name_ko);

-- pet_morph_rls uq_pet_morph_rls_client  |  CONSTRAINT
ALTER TABLE ONLY pet_morph_rls
    ADD CONSTRAINT uq_pet_morph_rls_client UNIQUE (client_id, client_change_id);

-- routine_pet_rls uq_routine_pet_rls  |  CONSTRAINT
ALTER TABLE ONLY routine_pet_rls
    ADD CONSTRAINT uq_routine_pet_rls UNIQUE (routine_id, pet_id);

-- user_mst user_mst_pkey  |  CONSTRAINT
ALTER TABLE ONLY user_mst
    ADD CONSTRAINT user_mst_pkey PRIMARY KEY (id);

-- user_oauth_rls user_oauth_rls_pkey  |  CONSTRAINT
ALTER TABLE ONLY user_oauth_rls
    ADD CONSTRAINT user_oauth_rls_pkey PRIMARY KEY (id);

-- weight_dtl weight_dtl_pkey  |  CONSTRAINT
ALTER TABLE ONLY weight_dtl
    ADD CONSTRAINT weight_dtl_pkey PRIMARY KEY (id);

-- idx_cleaning_dtl_pet_calendar  |  INDEX
CREATE INDEX idx_cleaning_dtl_pet_calendar ON cleaning_dtl USING btree (pet_id, cleaned_at DESC) WHERE (deleted_at IS NULL);

-- INDEX idx_cleaning_dtl_pet_calendar  |  COMMENT
COMMENT ON INDEX idx_cleaning_dtl_pet_calendar IS '캘린더 집계 쿼리 전용 partial 인덱스';

-- idx_cleaning_dtl_pet_time  |  INDEX
CREATE INDEX idx_cleaning_dtl_pet_time ON cleaning_dtl USING btree (pet_id, cleaned_at DESC) WHERE (deleted_at IS NULL);

-- idx_cleaning_dtl_routine  |  INDEX
CREATE INDEX idx_cleaning_dtl_routine ON cleaning_dtl USING btree (routine_id) WHERE ((routine_id IS NOT NULL) AND (deleted_at IS NULL));

-- idx_cleaning_dtl_routine_log  |  INDEX
CREATE INDEX idx_cleaning_dtl_routine_log ON cleaning_dtl USING btree (routine_log_id);

-- idx_device_token_rls_user_platform  |  INDEX
CREATE INDEX idx_device_token_rls_user_platform ON device_token_rls USING btree (user_id, platform);

-- idx_feeding_dtl_pet_calendar  |  INDEX
CREATE INDEX idx_feeding_dtl_pet_calendar ON feeding_dtl USING btree (pet_id, fed_at DESC) WHERE (deleted_at IS NULL);

-- INDEX idx_feeding_dtl_pet_calendar  |  COMMENT
COMMENT ON INDEX idx_feeding_dtl_pet_calendar IS '캘린더 집계 쿼리 전용 partial 인덱스';

-- idx_feeding_dtl_pet_time  |  INDEX
CREATE INDEX idx_feeding_dtl_pet_time ON feeding_dtl USING btree (pet_id, fed_at DESC) WHERE (deleted_at IS NULL);

-- idx_feeding_dtl_refused  |  INDEX
CREATE INDEX idx_feeding_dtl_refused ON feeding_dtl USING btree (pet_id, fed_at DESC) WHERE (((refused_yn)::text = 'Y'::text) AND (deleted_at IS NULL));

-- idx_feeding_dtl_routine  |  INDEX
CREATE INDEX idx_feeding_dtl_routine ON feeding_dtl USING btree (routine_id, fed_at DESC) WHERE (deleted_at IS NULL);

-- idx_feeding_dtl_routine_log  |  INDEX
CREATE INDEX idx_feeding_dtl_routine_log ON feeding_dtl USING btree (routine_log_id);

-- idx_hatch_hatched_pet  |  INDEX
CREATE INDEX idx_hatch_hatched_pet ON laying_hatch_dtl USING btree (hatched_pet_id) WHERE (hatched_pet_id IS NOT NULL);

-- idx_hatch_laying_status  |  INDEX
CREATE INDEX idx_hatch_laying_status ON laying_hatch_dtl USING btree (laying_id, status);

-- idx_laying_dtl_mating  |  INDEX
CREATE INDEX idx_laying_dtl_mating ON laying_dtl USING btree (mating_id) WHERE (mating_id IS NOT NULL);

-- idx_laying_dtl_pet_time  |  INDEX
CREATE INDEX idx_laying_dtl_pet_time ON laying_dtl USING btree (pet_id, laid_at DESC) WHERE (deleted_at IS NULL);

-- idx_mating_dtl_female  |  INDEX
CREATE INDEX idx_mating_dtl_female ON mating_dtl USING btree (female_pet_id, tried_at DESC) WHERE (deleted_at IS NULL);

-- idx_mating_dtl_male  |  INDEX
CREATE INDEX idx_mating_dtl_male ON mating_dtl USING btree (male_pet_id, tried_at DESC) WHERE (deleted_at IS NULL);

-- idx_mating_dtl_season  |  INDEX
CREATE INDEX idx_mating_dtl_season ON mating_dtl USING btree (season_label);

-- idx_memo_dtl_pet_time  |  INDEX
CREATE INDEX idx_memo_dtl_pet_time ON memo_dtl USING btree (pet_id, logged_at DESC) WHERE (deleted_at IS NULL);

-- idx_memo_dtl_routine  |  INDEX
CREATE INDEX idx_memo_dtl_routine ON memo_dtl USING btree (routine_id) WHERE ((routine_id IS NOT NULL) AND (deleted_at IS NULL));

-- idx_memo_dtl_routine_log  |  INDEX
CREATE INDEX idx_memo_dtl_routine_log ON memo_dtl USING btree (routine_log_id);

-- idx_memo_tag_cd_active_order  |  INDEX
CREATE INDEX idx_memo_tag_cd_active_order ON memo_tag_cd USING btree (is_active, display_order);

-- idx_memo_tag_rls_tag  |  INDEX
CREATE INDEX idx_memo_tag_rls_tag ON memo_tag_rls USING btree (tag_id, memo_id);

-- idx_memo_vet_ext_next_visit  |  INDEX
CREATE INDEX idx_memo_vet_ext_next_visit ON memo_vet_ext_dtl USING btree (next_visit_at) WHERE (next_visit_at IS NOT NULL);

-- idx_morph_cd_alias_trgm  |  INDEX
CREATE INDEX idx_morph_cd_alias_trgm ON morph_cd USING gin (alias_list gin_trgm_ops) WHERE (alias_list IS NOT NULL);

-- idx_morph_cd_health_concern  |  INDEX
CREATE INDEX idx_morph_cd_health_concern ON morph_cd USING btree (species_id, display_order) WHERE (has_health_concern = true);

-- idx_morph_cd_name_ko_trgm  |  INDEX
CREATE INDEX idx_morph_cd_name_ko_trgm ON morph_cd USING gin (name_ko gin_trgm_ops);

-- idx_morph_cd_species  |  INDEX
CREATE INDEX idx_morph_cd_species ON morph_cd USING btree (species_id) WHERE (is_active = true);

-- idx_morph_cd_species_order  |  INDEX
CREATE INDEX idx_morph_cd_species_order ON morph_cd USING btree (species_id, is_active, display_order);

-- idx_nfc_tag_bind_hst_tag  |  INDEX
CREATE INDEX idx_nfc_tag_bind_hst_tag ON nfc_tag_bind_hst USING btree (tag_cd, id DESC);

-- idx_nfc_tag_mst_batch  |  INDEX
CREATE INDEX idx_nfc_tag_mst_batch ON nfc_tag_mst USING btree (batch_no) WHERE (batch_no IS NOT NULL);

-- idx_nfc_tag_mst_pet  |  INDEX
CREATE INDEX idx_nfc_tag_mst_pet ON nfc_tag_mst USING btree (pet_id);

-- idx_nfc_tag_mst_status  |  INDEX
CREATE INDEX idx_nfc_tag_mst_status ON nfc_tag_mst USING btree (status);

-- idx_nfc_tag_mst_user  |  INDEX
CREATE INDEX idx_nfc_tag_mst_user ON nfc_tag_mst USING btree (user_id);

-- idx_notification_log_status  |  INDEX
CREATE INDEX idx_notification_log_status ON notification_log_dtl USING btree (status, sent_at);

-- idx_notification_log_type  |  INDEX
CREATE INDEX idx_notification_log_type ON notification_log_dtl USING btree (user_id, notification_type, sent_at DESC);

-- idx_notification_log_user_time  |  INDEX
CREATE INDEX idx_notification_log_user_time ON notification_log_dtl USING btree (user_id, sent_at DESC);

-- idx_pet_keeper_owner  |  INDEX
CREATE UNIQUE INDEX idx_pet_keeper_owner ON pet_keeper_rls USING btree (pet_id) WHERE ((role)::text = 'OWNER'::text);

-- idx_pet_keeper_user  |  INDEX
CREATE INDEX idx_pet_keeper_user ON pet_keeper_rls USING btree (user_id);

-- idx_pet_morph_rls_morph_id  |  INDEX
CREATE INDEX idx_pet_morph_rls_morph_id ON pet_morph_rls USING btree (morph_id, pet_id);

-- idx_pet_mst_orphaned  |  INDEX
CREATE INDEX idx_pet_mst_orphaned ON pet_mst USING btree (id) WHERE (is_orphaned = true);

-- idx_pet_mst_serial_no  |  INDEX
CREATE UNIQUE INDEX idx_pet_mst_serial_no ON pet_mst USING btree (serial_no) WHERE (deleted_at IS NULL);

-- idx_pet_mst_species_id  |  INDEX
CREATE INDEX idx_pet_mst_species_id ON pet_mst USING btree (species_id);

-- idx_pet_mst_user_id  |  INDEX
CREATE INDEX idx_pet_mst_user_id ON pet_mst USING btree (user_id, deleted_at);

-- idx_pet_relation_child  |  INDEX
CREATE INDEX idx_pet_relation_child ON pet_relation_rls USING btree (child_pet_id);

-- idx_pet_share_inv_batch  |  INDEX
CREATE INDEX idx_pet_share_inv_batch ON pet_share_invitation USING btree (batch_id);

-- idx_pet_share_inv_invitee  |  INDEX
CREATE INDEX idx_pet_share_inv_invitee ON pet_share_invitation USING btree (invitee_user_id, status);

-- idx_pet_share_inv_pending  |  INDEX
CREATE UNIQUE INDEX idx_pet_share_inv_pending ON pet_share_invitation USING btree (pet_id, invitee_user_id) WHERE ((status)::text = 'PENDING'::text);

-- idx_pet_share_inv_pet  |  INDEX
CREATE INDEX idx_pet_share_inv_pet ON pet_share_invitation USING btree (pet_id, status);

-- idx_photo_entity  |  INDEX
CREATE INDEX idx_photo_entity ON photo_dtl USING btree (entity_type, entity_id, display_order);

-- idx_photo_entity_time  |  INDEX
CREATE INDEX idx_photo_entity_time ON photo_dtl USING btree (entity_type, entity_id, taken_at DESC) WHERE (deleted_at IS NULL);

-- idx_photo_laying  |  INDEX
CREATE INDEX idx_photo_laying ON photo_dtl USING btree (entity_id, taken_at DESC) WHERE (((entity_type)::text = 'LAYING'::text) AND (deleted_at IS NULL));

-- idx_photo_mating  |  INDEX
CREATE INDEX idx_photo_mating ON photo_dtl USING btree (entity_id, taken_at DESC) WHERE (((entity_type)::text = 'MATING'::text) AND (deleted_at IS NULL));

-- idx_photo_memo  |  INDEX
CREATE INDEX idx_photo_memo ON photo_dtl USING btree (entity_id, taken_at DESC) WHERE (((entity_type)::text = 'MEMO'::text) AND (deleted_at IS NULL));

-- idx_photo_pet  |  INDEX
CREATE INDEX idx_photo_pet ON photo_dtl USING btree (entity_id, taken_at DESC) WHERE (((entity_type)::text = 'PET'::text) AND (deleted_at IS NULL));

-- idx_post_comment_dtl_parent  |  INDEX
CREATE INDEX idx_post_comment_dtl_parent ON post_comment_dtl USING btree (parent_comment_id) WHERE (parent_comment_id IS NOT NULL);

-- idx_post_comment_dtl_post  |  INDEX
CREATE INDEX idx_post_comment_dtl_post ON post_comment_dtl USING btree (post_id, created_at) WHERE (deleted_at IS NULL);

-- idx_post_like_rls_user  |  INDEX
CREATE INDEX idx_post_like_rls_user ON post_like_rls USING btree (user_id);

-- idx_post_mst_category_time  |  INDEX
CREATE INDEX idx_post_mst_category_time ON post_mst USING btree (category_id, created_at DESC) WHERE (deleted_at IS NULL);

-- idx_post_mst_pinned_time  |  INDEX
CREATE INDEX idx_post_mst_pinned_time ON post_mst USING btree (pinned_yn, created_at DESC);

-- idx_post_mst_user_time  |  INDEX
CREATE INDEX idx_post_mst_user_time ON post_mst USING btree (user_id, created_at DESC) WHERE (deleted_at IS NULL);

-- idx_post_photo_dtl_post  |  INDEX
CREATE INDEX idx_post_photo_dtl_post ON post_photo_dtl USING btree (post_id, display_order);

-- idx_routine_log_dtl_pet_time  |  INDEX
CREATE INDEX idx_routine_log_dtl_pet_time ON routine_log_dtl USING btree (pet_id, executed_at DESC) WHERE (deleted_at IS NULL);

-- idx_routine_log_dtl_progress  |  INDEX
CREATE INDEX idx_routine_log_dtl_progress ON routine_log_dtl USING btree (routine_id, pet_id, executed_at DESC) WHERE ((deleted_at IS NULL) AND ((status)::text = 'COMPLETED'::text));

-- idx_routine_log_dtl_routine_time  |  INDEX
CREATE INDEX idx_routine_log_dtl_routine_time ON routine_log_dtl USING btree (routine_id, executed_at DESC) WHERE (deleted_at IS NULL);

-- idx_routine_mst_next_due  |  INDEX
CREATE INDEX idx_routine_mst_next_due ON routine_mst USING btree (next_due_at) WHERE ((is_active = true) AND (is_alarm_enabled = true));

-- idx_routine_mst_user_active  |  INDEX
CREATE INDEX idx_routine_mst_user_active ON routine_mst USING btree (user_id, is_active);

-- idx_routine_pet_rls_pet  |  INDEX
CREATE INDEX idx_routine_pet_rls_pet ON routine_pet_rls USING btree (pet_id);

-- idx_routine_pet_rls_routine  |  INDEX
CREATE INDEX idx_routine_pet_rls_routine ON routine_pet_rls USING btree (routine_id);

-- idx_s3_delete_queue_pending  |  INDEX
CREATE INDEX idx_s3_delete_queue_pending ON s3_delete_queue_dtl USING btree (attempt_cnt, id) WHERE (succeeded_at IS NULL);

-- idx_species_cd_category_order  |  INDEX
CREATE INDEX idx_species_cd_category_order ON species_cd USING btree (category, is_active, display_order);

-- idx_species_cd_name_ko_trgm  |  INDEX
CREATE INDEX idx_species_cd_name_ko_trgm ON species_cd USING gin (name_ko gin_trgm_ops);

-- idx_species_cd_subcategory  |  INDEX
CREATE INDEX idx_species_cd_subcategory ON species_cd USING btree (subcategory, is_active);

-- idx_user_mst_email_active  |  INDEX
CREATE UNIQUE INDEX idx_user_mst_email_active ON user_mst USING btree (email) WHERE (deleted_at IS NULL);

-- idx_user_mst_share_code  |  INDEX
CREATE UNIQUE INDEX idx_user_mst_share_code ON user_mst USING btree (share_code) WHERE (share_code IS NOT NULL);

-- idx_user_oauth_rls_provider_pid  |  INDEX
CREATE INDEX idx_user_oauth_rls_provider_pid ON user_oauth_rls USING btree (provider, provider_user_id);

-- idx_user_oauth_rls_user_id  |  INDEX
CREATE INDEX idx_user_oauth_rls_user_id ON user_oauth_rls USING btree (user_id);

-- idx_weight_dtl_pet_calendar  |  INDEX
CREATE INDEX idx_weight_dtl_pet_calendar ON weight_dtl USING btree (pet_id, measured_at DESC) WHERE (deleted_at IS NULL);

-- INDEX idx_weight_dtl_pet_calendar  |  COMMENT
COMMENT ON INDEX idx_weight_dtl_pet_calendar IS '캘린더 집계 쿼리 전용 partial 인덱스';

-- idx_weight_dtl_pet_time  |  INDEX
CREATE INDEX idx_weight_dtl_pet_time ON weight_dtl USING btree (pet_id, measured_at DESC) WHERE (deleted_at IS NULL);

-- idx_weight_dtl_routine_log  |  INDEX
CREATE INDEX idx_weight_dtl_routine_log ON weight_dtl USING btree (routine_log_id);

-- cleaning_dtl trg_cleaning_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_cleaning_dtl_sync_version BEFORE UPDATE ON cleaning_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- feeding_dtl trg_feeding_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_feeding_dtl_sync_version BEFORE UPDATE ON feeding_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- laying_dtl trg_laying_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_laying_dtl_sync_version BEFORE UPDATE ON laying_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- laying_hatch_dtl trg_laying_hatch_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_laying_hatch_dtl_sync_version BEFORE UPDATE ON laying_hatch_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- mating_dtl trg_mating_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_mating_dtl_sync_version BEFORE UPDATE ON mating_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- memo_dtl trg_memo_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_memo_dtl_sync_version BEFORE UPDATE ON memo_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- memo_tag_rls trg_memo_tag_rls_sync_version  |  TRIGGER
CREATE TRIGGER trg_memo_tag_rls_sync_version BEFORE UPDATE ON memo_tag_rls FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- memo_vet_ext_dtl trg_memo_vet_ext_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_memo_vet_ext_dtl_sync_version BEFORE UPDATE ON memo_vet_ext_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- pet_mst trg_pet_mst_sync_version  |  TRIGGER
CREATE TRIGGER trg_pet_mst_sync_version BEFORE UPDATE ON pet_mst FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- post_comment_dtl trg_post_comment_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_post_comment_dtl_sync_version BEFORE UPDATE ON post_comment_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- post_like_rls trg_post_like_rls_sync_version  |  TRIGGER
CREATE TRIGGER trg_post_like_rls_sync_version BEFORE UPDATE ON post_like_rls FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- post_mst trg_post_mst_sync_version  |  TRIGGER
CREATE TRIGGER trg_post_mst_sync_version BEFORE UPDATE ON post_mst FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- weight_dtl trg_weight_dtl_sync_version  |  TRIGGER
CREATE TRIGGER trg_weight_dtl_sync_version BEFORE UPDATE ON weight_dtl FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- admin_role_rls fk_admin_role_granter  |  FK CONSTRAINT
ALTER TABLE ONLY admin_role_rls
    ADD CONSTRAINT fk_admin_role_granter FOREIGN KEY (granted_by) REFERENCES user_mst(id) ON DELETE SET NULL;

-- admin_role_rls fk_admin_role_user  |  FK CONSTRAINT
ALTER TABLE ONLY admin_role_rls
    ADD CONSTRAINT fk_admin_role_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- cleaning_dtl fk_cleaning_dtl_pet  |  FK CONSTRAINT
ALTER TABLE ONLY cleaning_dtl
    ADD CONSTRAINT fk_cleaning_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- cleaning_dtl fk_cleaning_dtl_routine  |  FK CONSTRAINT
ALTER TABLE ONLY cleaning_dtl
    ADD CONSTRAINT fk_cleaning_dtl_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL;

-- device_token_rls fk_device_token_rls_user  |  FK CONSTRAINT
ALTER TABLE ONLY device_token_rls
    ADD CONSTRAINT fk_device_token_rls_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- feeding_dtl fk_feeding_dtl_pet  |  FK CONSTRAINT
ALTER TABLE ONLY feeding_dtl
    ADD CONSTRAINT fk_feeding_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- feeding_dtl fk_feeding_dtl_routine  |  FK CONSTRAINT
ALTER TABLE ONLY feeding_dtl
    ADD CONSTRAINT fk_feeding_dtl_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL;

-- laying_hatch_dtl fk_hatch_laying  |  FK CONSTRAINT
ALTER TABLE ONLY laying_hatch_dtl
    ADD CONSTRAINT fk_hatch_laying FOREIGN KEY (laying_id) REFERENCES laying_dtl(id) ON DELETE CASCADE;

-- laying_hatch_dtl fk_hatch_pet  |  FK CONSTRAINT
ALTER TABLE ONLY laying_hatch_dtl
    ADD CONSTRAINT fk_hatch_pet FOREIGN KEY (hatched_pet_id) REFERENCES pet_mst(id) ON DELETE SET NULL;

-- memo_dtl fk_health_memo_dtl_pet  |  FK CONSTRAINT
ALTER TABLE ONLY memo_dtl
    ADD CONSTRAINT fk_health_memo_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- laying_dtl fk_laying_dtl_mating  |  FK CONSTRAINT
ALTER TABLE ONLY laying_dtl
    ADD CONSTRAINT fk_laying_dtl_mating FOREIGN KEY (mating_id) REFERENCES mating_dtl(id) ON DELETE SET NULL;

-- laying_dtl fk_laying_dtl_pet  |  FK CONSTRAINT
ALTER TABLE ONLY laying_dtl
    ADD CONSTRAINT fk_laying_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- mating_dtl fk_mating_dtl_female  |  FK CONSTRAINT
ALTER TABLE ONLY mating_dtl
    ADD CONSTRAINT fk_mating_dtl_female FOREIGN KEY (female_pet_id) REFERENCES pet_mst(id) ON DELETE SET NULL;

-- mating_dtl fk_mating_dtl_male  |  FK CONSTRAINT
ALTER TABLE ONLY mating_dtl
    ADD CONSTRAINT fk_mating_dtl_male FOREIGN KEY (male_pet_id) REFERENCES pet_mst(id) ON DELETE SET NULL;

-- memo_dtl fk_memo_dtl_routine  |  FK CONSTRAINT
ALTER TABLE ONLY memo_dtl
    ADD CONSTRAINT fk_memo_dtl_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL;

-- memo_tag_rls fk_memo_tag_rls_memo  |  FK CONSTRAINT
ALTER TABLE ONLY memo_tag_rls
    ADD CONSTRAINT fk_memo_tag_rls_memo FOREIGN KEY (memo_id) REFERENCES memo_dtl(id) ON DELETE CASCADE;

-- memo_tag_rls fk_memo_tag_rls_tag  |  FK CONSTRAINT
ALTER TABLE ONLY memo_tag_rls
    ADD CONSTRAINT fk_memo_tag_rls_tag FOREIGN KEY (tag_id) REFERENCES memo_tag_cd(id) ON DELETE RESTRICT;

-- memo_vet_ext_dtl fk_memo_vet_ext_memo  |  FK CONSTRAINT
ALTER TABLE ONLY memo_vet_ext_dtl
    ADD CONSTRAINT fk_memo_vet_ext_memo FOREIGN KEY (memo_id) REFERENCES memo_dtl(id) ON DELETE CASCADE;

-- morph_cd fk_morph_cd_species  |  FK CONSTRAINT
ALTER TABLE ONLY morph_cd
    ADD CONSTRAINT fk_morph_cd_species FOREIGN KEY (species_id) REFERENCES species_cd(id);

-- nfc_tag_mst fk_nfc_tag_mst_pet  |  FK CONSTRAINT
ALTER TABLE ONLY nfc_tag_mst
    ADD CONSTRAINT fk_nfc_tag_mst_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE SET NULL;

-- nfc_tag_mst fk_nfc_tag_mst_user  |  FK CONSTRAINT
ALTER TABLE ONLY nfc_tag_mst
    ADD CONSTRAINT fk_nfc_tag_mst_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE SET NULL;

-- notification_log_dtl fk_notification_log_pet  |  FK CONSTRAINT
ALTER TABLE ONLY notification_log_dtl
    ADD CONSTRAINT fk_notification_log_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE SET NULL;

-- notification_log_dtl fk_notification_log_routine  |  FK CONSTRAINT
ALTER TABLE ONLY notification_log_dtl
    ADD CONSTRAINT fk_notification_log_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL;

-- notification_log_dtl fk_notification_log_user  |  FK CONSTRAINT
ALTER TABLE ONLY notification_log_dtl
    ADD CONSTRAINT fk_notification_log_user FOREIGN KEY (user_id) REFERENCES user_mst(id);

-- pet_keeper_rls fk_pet_keeper_pet  |  FK CONSTRAINT
ALTER TABLE ONLY pet_keeper_rls
    ADD CONSTRAINT fk_pet_keeper_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- pet_keeper_rls fk_pet_keeper_user  |  FK CONSTRAINT
ALTER TABLE ONLY pet_keeper_rls
    ADD CONSTRAINT fk_pet_keeper_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- pet_morph_rls fk_pet_morph_rls_morph  |  FK CONSTRAINT
ALTER TABLE ONLY pet_morph_rls
    ADD CONSTRAINT fk_pet_morph_rls_morph FOREIGN KEY (morph_id) REFERENCES morph_cd(id) ON DELETE RESTRICT;

-- pet_morph_rls fk_pet_morph_rls_pet  |  FK CONSTRAINT
ALTER TABLE ONLY pet_morph_rls
    ADD CONSTRAINT fk_pet_morph_rls_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- pet_mst fk_pet_mst_profile_photo  |  FK CONSTRAINT
ALTER TABLE ONLY pet_mst
    ADD CONSTRAINT fk_pet_mst_profile_photo FOREIGN KEY (profile_photo_id) REFERENCES photo_dtl(id) ON DELETE SET NULL;

-- pet_mst fk_pet_mst_species  |  FK CONSTRAINT
ALTER TABLE ONLY pet_mst
    ADD CONSTRAINT fk_pet_mst_species FOREIGN KEY (species_id) REFERENCES species_cd(id);

-- pet_mst fk_pet_mst_user  |  FK CONSTRAINT
ALTER TABLE ONLY pet_mst
    ADD CONSTRAINT fk_pet_mst_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- pet_relation_rls fk_pet_relation_child  |  FK CONSTRAINT
ALTER TABLE ONLY pet_relation_rls
    ADD CONSTRAINT fk_pet_relation_child FOREIGN KEY (child_pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- pet_relation_rls fk_pet_relation_parent  |  FK CONSTRAINT
ALTER TABLE ONLY pet_relation_rls
    ADD CONSTRAINT fk_pet_relation_parent FOREIGN KEY (parent_pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- pet_share_invitation fk_pet_share_inv_invitee  |  FK CONSTRAINT
ALTER TABLE ONLY pet_share_invitation
    ADD CONSTRAINT fk_pet_share_inv_invitee FOREIGN KEY (invitee_user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- pet_share_invitation fk_pet_share_inv_inviter  |  FK CONSTRAINT
ALTER TABLE ONLY pet_share_invitation
    ADD CONSTRAINT fk_pet_share_inv_inviter FOREIGN KEY (inviter_user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- pet_share_invitation fk_pet_share_inv_pet  |  FK CONSTRAINT
ALTER TABLE ONLY pet_share_invitation
    ADD CONSTRAINT fk_pet_share_inv_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- post_comment_dtl fk_post_comment_parent  |  FK CONSTRAINT
ALTER TABLE ONLY post_comment_dtl
    ADD CONSTRAINT fk_post_comment_parent FOREIGN KEY (parent_comment_id) REFERENCES post_comment_dtl(id) ON DELETE CASCADE;

-- post_comment_dtl fk_post_comment_post  |  FK CONSTRAINT
ALTER TABLE ONLY post_comment_dtl
    ADD CONSTRAINT fk_post_comment_post FOREIGN KEY (post_id) REFERENCES post_mst(id) ON DELETE CASCADE;

-- post_comment_dtl fk_post_comment_user  |  FK CONSTRAINT
ALTER TABLE ONLY post_comment_dtl
    ADD CONSTRAINT fk_post_comment_user FOREIGN KEY (user_id) REFERENCES user_mst(id);

-- post_like_rls fk_post_like_rls_post  |  FK CONSTRAINT
ALTER TABLE ONLY post_like_rls
    ADD CONSTRAINT fk_post_like_rls_post FOREIGN KEY (post_id) REFERENCES post_mst(id) ON DELETE CASCADE;

-- post_like_rls fk_post_like_rls_user  |  FK CONSTRAINT
ALTER TABLE ONLY post_like_rls
    ADD CONSTRAINT fk_post_like_rls_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- post_mst fk_post_mst_category  |  FK CONSTRAINT
ALTER TABLE ONLY post_mst
    ADD CONSTRAINT fk_post_mst_category FOREIGN KEY (category_id) REFERENCES post_category_cd(id);

-- post_mst fk_post_mst_user  |  FK CONSTRAINT
ALTER TABLE ONLY post_mst
    ADD CONSTRAINT fk_post_mst_user FOREIGN KEY (user_id) REFERENCES user_mst(id);

-- post_photo_dtl fk_post_photo_dtl_post  |  FK CONSTRAINT
ALTER TABLE ONLY post_photo_dtl
    ADD CONSTRAINT fk_post_photo_dtl_post FOREIGN KEY (post_id) REFERENCES post_mst(id) ON DELETE CASCADE;

-- routine_log_dtl fk_routine_log_dtl_pet  |  FK CONSTRAINT
ALTER TABLE ONLY routine_log_dtl
    ADD CONSTRAINT fk_routine_log_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- routine_log_dtl fk_routine_log_dtl_routine  |  FK CONSTRAINT
ALTER TABLE ONLY routine_log_dtl
    ADD CONSTRAINT fk_routine_log_dtl_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE CASCADE;

-- routine_mst fk_routine_mst_user  |  FK CONSTRAINT
ALTER TABLE ONLY routine_mst
    ADD CONSTRAINT fk_routine_mst_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- routine_pet_rls fk_routine_pet_rls_pet  |  FK CONSTRAINT
ALTER TABLE ONLY routine_pet_rls
    ADD CONSTRAINT fk_routine_pet_rls_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- routine_pet_rls fk_routine_pet_rls_routine  |  FK CONSTRAINT
ALTER TABLE ONLY routine_pet_rls
    ADD CONSTRAINT fk_routine_pet_rls_routine FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE CASCADE;

-- user_oauth_rls fk_user_oauth_rls_user  |  FK CONSTRAINT
ALTER TABLE ONLY user_oauth_rls
    ADD CONSTRAINT fk_user_oauth_rls_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE;

-- weight_dtl fk_weight_dtl_pet  |  FK CONSTRAINT
ALTER TABLE ONLY weight_dtl
    ADD CONSTRAINT fk_weight_dtl_pet FOREIGN KEY (pet_id) REFERENCES pet_mst(id) ON DELETE CASCADE;

-- weight_dtl weight_dtl_routine_id_fkey  |  FK CONSTRAINT
ALTER TABLE ONLY weight_dtl
    ADD CONSTRAINT weight_dtl_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES routine_mst(id) ON DELETE SET NULL;



-- =====================================================================
-- 코드성 시드 데이터
-- =====================================================================
-- 구 V3(post_category_cd) / V16·V38(memo_tag_cd) / V11(serial_pool_stat_mst) 이
-- 심던 값이다. 스키마 덤프에는 데이터가 안 들어가므로 여기에 따로 옮겨 적었다.
--
-- id 를 명시하는 이유: 이 값들은 코드에서 이름(code)으로 찾지만, 개발/운영 DB의
-- id 가 갈리면 덤프 비교가 매번 어긋난다. 뒤의 setval 로 시퀀스도 맞춰준다.
--
-- created_at/updated_at 은 적지 않는다 — DEFAULT now() 가 채운다.
-- 덤프에 찍힌 시각을 그대로 옮기면 "언제 스쿼시했는가"가 데이터에 박혀버린다.
--
-- ON CONFLICT DO NOTHING 은 붙이지 않는다. 이 파일은 빈 DB에만 적용되고,
-- 조용히 넘어가면 시드 누락을 못 잡는다.
-- =====================================================================

-- 메모 태그 (구 V16 + V38)
-- ⚠️ VET 는 memo_vet_ext_dtl(병원명·비용·다음 방문일)을 필수로 끌고 온다. 지우지 말 것.
INSERT INTO memo_tag_cd (id, code, label_ko, label_en, color_code, display_order, is_system, is_active) VALUES
    (1, 'VET',      '병원', 'Hospital',   '#E74C3C',  1, TRUE, TRUE),
    (2, 'SHED',     '탈피', 'Shedding',   '#3498DB',  2, TRUE, TRUE),
    (3, 'BEHAVIOR', '행동', 'Behavior',   '#9B59B6',  3, TRUE, TRUE),
    (4, 'ETC',      '기타', 'Etc',        '#95A5A6', 99, TRUE, TRUE),
    (5, 'POOP',     '배변', 'Defecation', '#8D6E63',  4, TRUE, TRUE);

-- 커뮤니티 게시판 (구 V3)
INSERT INTO post_category_cd (id, code, name_ko, description, display_order, is_active) VALUES
    (1, 'FREE',     '자유게시판', '일상·사진 공유',                        1, TRUE),
    (2, 'QNA',      'QnA',        '사육 관련 질문·답변',                    2, TRUE),
    (3, 'INFO',     '정보게시판', '종별 사육 정보·팁',                      3, TRUE),
    (4, 'ADOPTION', '분양게시판', '개체 분양 정보 공유 (결제·소유권 이전은 4차)', 4, TRUE);

-- 일련번호 풀 용량 (구 V11)
-- 32자 풀(0/O/I/1 제외) 기준 32^n. 6자리로 시작해 사용률 80% 도달 시 7자리로 확장한다.
INSERT INTO serial_pool_stat_mst (id, serial_length, total_capacity, is_current) VALUES
    (1, 6,       1073741824, TRUE),   -- 32^6
    (2, 7,      34359738368, FALSE),  -- 32^7
    (3, 8, 1099511627776,    FALSE);  -- 32^8

-- 위에서 id 를 직접 넣었으므로 시퀀스가 뒤처져 있다. 맞춰주지 않으면
-- 다음 INSERT 가 id=1 을 다시 쓰려다 PK 중복으로 터진다.
SELECT setval('memo_tag_cd_id_seq',          5, TRUE);
SELECT setval('post_category_cd_id_seq',     4, TRUE);
SELECT setval('serial_pool_stat_mst_id_seq', 3, TRUE);
