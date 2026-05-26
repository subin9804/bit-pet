package io.bitpet.record.memo.dto;

import java.util.List;

public record MemoListResponse(
        List<MemoResponse> items,
        long totalElements
) {}
