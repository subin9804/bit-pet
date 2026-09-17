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
        boolean blinded,
        List<PostPhotoResponse> photos,
        Instant createdAt,
        Instant updatedAt
) {
    /** 블라인드면 제목·본문·사진을 치환해서 내보낸다 — 원문은 DB 에 그대로 남는다 */
    public static PostDetailResponse of(PostMst p, boolean likedByMe, List<PostPhotoResponse> photos,
                                        String authorName, String authorImageUrl) {
        boolean blinded = p.isBlinded();
        return new PostDetailResponse(
                p.getId(), p.getCategoryId(), p.getUserId(),
                authorName, authorImageUrl,
                blinded ? BlindMask.TITLE   : p.getTitle(),
                blinded ? BlindMask.CONTENT : p.getContent(),
                p.getViewCount(), p.getLikeCount(), p.getCommentCount(),
                likedByMe, p.isPinned(), blinded,
                blinded ? List.of() : photos,
                p.getCreatedAt(), p.getUpdatedAt()
        );
    }
}
