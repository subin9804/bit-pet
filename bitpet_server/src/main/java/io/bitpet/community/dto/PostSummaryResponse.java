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
        boolean blinded,
        String thumbnailUrl,
        Instant createdAt
) {
    /** 블라인드면 목록에서도 제목·썸네일을 가린다 (제목만으로 충분히 모욕적일 수 있다) */
    public static PostSummaryResponse of(PostMst p, String thumbnailUrl,
                                         String authorName, String authorImageUrl,
                                         boolean likedByMe) {
        boolean blinded = p.isBlinded();
        return new PostSummaryResponse(
                p.getId(), p.getCategoryId(), p.getUserId(),
                authorName, authorImageUrl,
                blinded ? BlindMask.TITLE : p.getTitle(),
                p.getViewCount(), p.getLikeCount(), p.getCommentCount(),
                likedByMe, p.isPinned(), blinded,
                blinded ? null : thumbnailUrl,
                p.getCreatedAt()
        );
    }
}
