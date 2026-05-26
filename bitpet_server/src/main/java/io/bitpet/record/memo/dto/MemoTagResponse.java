package io.bitpet.record.memo.dto;

import io.bitpet.record.memo.domain.MemoTagCd;

public record MemoTagResponse(
        String code,
        String label,
        int order
) {
    public static MemoTagResponse from(MemoTagCd tag) {
        return new MemoTagResponse(tag.getCode(), tag.getLabelKo(), tag.getDisplayOrder());
    }
}
