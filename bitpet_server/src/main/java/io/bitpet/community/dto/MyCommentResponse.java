package io.bitpet.community.dto;

import io.bitpet.community.domain.PostCommentDtl;

import java.time.Instant;

/**
 * 마이페이지 > 내 게시글 의 '댓글' 탭 한 줄.
 *
 * <p>댓글만 보여주면 무슨 글에 단 건지 알 수 없어서 소속 게시글 정보를 같이 내린다.
 * 원글이 지워진 댓글은 목록에서 빼지 않고 {@code postDeleted = true} 로 표시한다 —
 * 조용히 사라지면 사용자는 자기 댓글이 삭제된 줄 안다.
 */
public record MyCommentResponse(
        Long id,
        Long postId,
        String postTitle,
        Long postCategoryId,
        boolean postDeleted,
        Long parentCommentId,
        String content,
        Instant createdAt
) {
    public static MyCommentResponse of(PostCommentDtl c, String postTitle, Long categoryId) {
        return new MyCommentResponse(
                c.getId(), c.getPostId(),
                postTitle != null ? postTitle : "삭제된 게시글",
                categoryId,
                postTitle == null,
                c.getParentCommentId(),
                c.getContent(), c.getCreatedAt()
        );
    }
}
