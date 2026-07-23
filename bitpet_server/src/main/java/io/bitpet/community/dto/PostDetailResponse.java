package io.bitpet.community.dto;

import io.bitpet.community.domain.PostMst;

import java.time.Instant;
import java.util.List;

public record PostDetailResponse(
        Long id,
        Long categoryId,
        Long userId,
        String authorName,
        String authorImageUrl,
        String title,
        String content,
        int viewCount,
        int likeCount,
        int commentCount,
        boolean likedByMe,
        boolean pinned,
        List<PostPhotoResponse> photos,
        Instant createdAt,
        Instant updatedAt
) {
    public static PostDetailResponse of(PostMst p, boolean likedByMe, List<PostPhotoResponse> photos,
                                        String authorName, String authorImageUrl) {
        return new PostDetailResponse(
                p.getId(), p.getCategoryId(), p.getUserId(),
                authorName, authorImageUrl,
                p.getTitle(), p.getContent(),
                p.getViewCount(), p.getLikeCount(), p.getCommentCount(),
                likedByMe, p.isPinned(), photos, p.getCreatedAt(), p.getUpdatedAt()
        );
    }
}
