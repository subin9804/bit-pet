package io.bitpet.community.dto;

import io.bitpet.community.domain.PostCommentDtl;

import java.time.Instant;
import java.util.List;

public record CommentResponse(
        Long id,
        Long postId,
        Long userId,
        Long parentCommentId,
        String content,
        List<CommentResponse> replies,
        Instant createdAt,
        Instant updatedAt
) {
    public static CommentResponse of(PostCommentDtl c, List<CommentResponse> replies) {
        return new CommentResponse(
                c.getId(), c.getPostId(), c.getUserId(), c.getParentCommentId(),
                c.getContent(), replies, c.getCreatedAt(), c.getUpdatedAt()
        );
    }
}
