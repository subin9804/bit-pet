package io.bitpet.community.dto;

import io.bitpet.community.domain.PostMst;

import java.time.Instant;

public record PostSummaryResponse(
        Long id,
        Long categoryId,
        Long userId,
        String title,
        int viewCount,
        int likeCount,
        int commentCount,
        String thumbnailUrl,
        Instant createdAt
) {
    public static PostSummaryResponse of(PostMst p, String thumbnailUrl) {
        return new PostSummaryResponse(
                p.getId(), p.getCategoryId(), p.getUserId(),
                p.getTitle(), p.getViewCount(), p.getLikeCount(), p.getCommentCount(),
                thumbnailUrl, p.getCreatedAt()
        );
    }
}
