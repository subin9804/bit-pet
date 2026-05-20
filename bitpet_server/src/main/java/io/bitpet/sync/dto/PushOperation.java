package io.bitpet.sync.dto;

import java.util.Map;
import java.util.UUID;

public record PushOperation(
        String resource,
        String op,
        UUID clientChangeId,
        Map<String, Object> data
) {}
