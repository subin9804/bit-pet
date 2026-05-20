package io.bitpet.sync.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record SyncChangesResponse(
        String cursor,
        boolean hasMore,
        Map<String, List<Map<String, Object>>> changes
) {}
