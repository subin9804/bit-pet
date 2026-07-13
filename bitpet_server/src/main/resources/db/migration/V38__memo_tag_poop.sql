-- =============================================================================
-- V38: memo_tag_cd 에 POOP(배변) 태그 추가
-- 청소는 cleaning_dtl 독립 유지, 배변만 메모 태그로 신규 편입.
-- 배변 부가정보는 별도 확장 테이블 없이 본문(content)으로 받는다.
-- =============================================================================

INSERT INTO memo_tag_cd (code, label_ko, label_en, color_code, display_order, is_system, is_active) VALUES
    ('POOP', '배변', 'Defecation', '#8D6E63', 4, TRUE, TRUE)
ON CONFLICT (code) DO NOTHING;
