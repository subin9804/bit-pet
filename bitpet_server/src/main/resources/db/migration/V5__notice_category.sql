-- 공지사항 게시판.
--
-- 별도 테이블을 만들지 않고 기존 post_mst 의 카테고리 하나로 둔 이유:
-- 공지도 결국 제목·본문·사진·조회수가 있는 게시글이고, 목록 조회·상세 조회·신고 처리가
-- 전부 똑같다. 테이블을 나누면 그 모든 경로를 두 벌씩 만들게 된다.
-- "누가 쓸 수 있나"만 다르므로, 그 차이는 서비스 계층의 권한 검사 한 줄로 처리한다.
--
-- display_order = 0 : 카테고리 탭에서 맨 앞에 온다 (FREE 가 1).
-- 목록 안에서의 상단 고정은 별개다 — post_mst.pinned_yn 이 담당하고,
-- PostService 가 공지 작성 시 자동으로 'Y' 로 만든다.
INSERT INTO post_category_cd (id, code, name_ko, description, display_order, is_active) VALUES
    (5, 'NOTICE', '공지사항', '운영자 공지', 0, TRUE);

-- id 를 직접 넣었으므로 시퀀스를 따라 올린다. 안 하면 다음 INSERT 가 id=5 를 다시 쓰려다
-- PK 중복으로 터진다 (V1 의 setval 과 같은 이유).
SELECT setval('post_category_cd_id_seq', 5, TRUE);
