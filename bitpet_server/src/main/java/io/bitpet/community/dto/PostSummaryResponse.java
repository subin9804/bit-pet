package io.bitpet.community.dto;

import io.bitpet.community.domain.PostMst;

import java.time.Instant;

public record PostSummaryResponse(
        Long id,
        Long categoryId,
        Long userId,
        String authorName,
        String authorImageUrl,
        String title,
        int viewCount,
        int likeCount,
        int commentCount,
        boolean likedByMe,
        boolean pinned,
        String thumbnailUrl,
        Instant createdAt
) {
    public static PostSummaryResponse of(PostMst p, String thumbnailUrl,
                                         String authorName, String authorImageUrl,
                                         boolean likedByMe) {
        return new PostSummaryResponse(
                p.getId(), p.getCategoryId(), p.getUserId(),
                authorName, authorImageUrl,
                p.getTitle(), p.getViewCount(), p.getLikeCount(), p.getCommentCount(),
                likedByMe, p.isPinned(), thumbnailUrl, p.getCreatedAt()
        );
    }
}
