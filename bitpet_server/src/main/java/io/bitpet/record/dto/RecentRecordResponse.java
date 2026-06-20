package io.bitpet.record.dto;

import java.time.Instant;

public record RecentRecordResponse(
        String recordType,
        Long id,
        Long petId,
        String petName,
        String colorCode,
        Instant createdAt,
        String summary,
        String memo
) {
    public static RecentRecordResponse of(String recordType, Long id, Long petId,
                                          String petName, String colorCode,
                                          Instant createdAt, String summary, String memo) {
        return new RecentRecordResponse(recordType, id, petId, petName, colorCode,
                createdAt, summary, memo);
    }
}
