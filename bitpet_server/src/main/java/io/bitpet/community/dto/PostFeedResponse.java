package io.bitpet.community.dto;

import java.util.List;

/**
 * 피드 한 묶음. 다음 묶음은 {@code ?cursor=nextCursor} 로 받는다.
 *
 * @param content    고정 글(첫 요청에만) + 일반 글
 * @param nextCursor 다음 요청에 넘길 값 — 이번 묶음 마지막 일반 글의 id. 더 없으면 null
 * @param hasMore    더 받을 글이 있는지
 */
public record PostFeedResponse(
        List<PostSummaryResponse> content,
        Long nextCursor,
        boolean hasMore
) {}
