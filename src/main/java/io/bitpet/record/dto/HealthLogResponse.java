package io.bitpet.record.dto;

import io.bitpet.record.domain.HealthMemoDtl;

import java.time.Instant;

public record HealthLogResponse(
        Long id,
        Long petId,
        String symptom,
        String treatment,
        String memo,
        Instant recordedAt,
        Instant createdAt,
        Instant updatedAt
) {
    public static HealthLogResponse from(HealthMemoDtl h) {
        return new HealthLogResponse(
                h.getId(), h.getPetId(), h.getSymptom(),
                h.getTreatment(), h.getMemo(), h.getRecordedAt(),
                h.getCreatedAt(), h.getUpdatedAt()
        );
    }
}
