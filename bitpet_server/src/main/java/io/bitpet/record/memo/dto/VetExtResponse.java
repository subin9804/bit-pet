package io.bitpet.record.memo.dto;

import io.bitpet.record.memo.domain.MemoVetExtDtl;

import java.time.Instant;

public record VetExtResponse(
        String clinicName,
        Integer cost,
        Instant nextVisitAt
) {
    public static VetExtResponse from(MemoVetExtDtl vet) {
        if (vet == null) return null;
        return new VetExtResponse(vet.getClinicName(), vet.getCost(), vet.getNextVisitAt());
    }
}
