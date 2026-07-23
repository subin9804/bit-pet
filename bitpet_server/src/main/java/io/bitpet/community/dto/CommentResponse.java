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
        List<CommentResponse> replies,
        Instant createdAt,
        Instant updatedAt
) {
    public static CommentResponse of(PostCommentDtl c, List<CommentResponse> replies,
                                     String authorName, String authorImageUrl, boolean postAuthor) {
        return new CommentResponse(
                c.getId(), c.getPostId(), c.getUserId(),
                authorName, authorImageUrl, postAuthor,
                c.getParentCommentId(),
                c.getContent(), replies, c.getCreatedAt(), c.getUpdatedAt()
        );
    }
}
