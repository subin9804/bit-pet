package io.bitpet.record.dto;

import java.time.Instant;

public record RecentRecordResponse(
        String type,
        Long recordId,
        Long petId,
        String petName,
        Instant occurredAt,
        String summary
) {}
