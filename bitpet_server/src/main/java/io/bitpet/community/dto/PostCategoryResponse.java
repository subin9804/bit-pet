package io.bitpet.community.dto;

import io.bitpet.community.domain.PostCategoryCd;

public record PostCategoryResponse(
        Long id,
        String code,
        String nameKo,
        String description,
        int displayOrder
) {
    public static PostCategoryResponse from(PostCategoryCd c) {
        return new PostCategoryResponse(c.getId(), c.getCode(), c.getNameKo(), c.getDescription(), c.getDisplayOrder());
    }
}
