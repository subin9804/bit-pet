package io.bitpet.record.mating.dto;

import java.util.List;

public record MatingListResponse(
        List<MatingResponse> items,
        long totalElements
) {}
