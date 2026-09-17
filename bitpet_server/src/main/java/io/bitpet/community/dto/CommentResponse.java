package io.bitpet.community.dto;

import io.bitpet.community.domain.PostCommentDtl;

import java.time.Instant;
import java.util.List;

public record CommentResponse(
        Long id,
        Long postId,
        Long userId,
        String authorName,
        String authorImageUrl,
        boolean postAuthor,
        Long parentCommentId,
        String content,
        boolean blinded,
        List<CommentResponse> replies,
        Instant createdAt,
        Instant updatedAt
) {
    /**
     * 블라인드된 댓글은 <b>지우지 않고 자리만 남긴다</b> — 대댓글이 달려 있으면 부모가
     * 사라질 때 대화가 통째로 무너진다.
     */
    public static CommentResponse of(PostCommentDtl c, List<CommentResponse> replies,
                                     String authorName, String authorImageUrl, boolean postAuthor) {
        boolean blinded = c.isBlinded();
        return new CommentResponse(
                c.getId(), c.getPostId(), c.getUserId(),
                authorName, authorImageUrl, postAuthor,
                c.getParentCommentId(),
                blinded ? BlindMask.COMMENT : c.getContent(),
                blinded, replies, c.getCreatedAt(), c.getUpdatedAt()
        );
    }
}
