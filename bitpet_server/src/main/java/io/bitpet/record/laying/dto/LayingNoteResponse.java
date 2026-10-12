package io.bitpet.record.laying.dto;

import io.bitpet.record.laying.domain.LayingNoteDtl;

import java.time.Instant;
import java.time.LocalDate;

public record LayingNoteResponse(
        Long noteId,
        Long layingId,
        LocalDate notedAt,
        String content,
        Instant createdAt,
        Instant updatedAt
) {
    public static LayingNoteResponse of(LayingNoteDtl note) {
        return new LayingNoteResponse(
                note.getId(),
                note.getLayingId(),
                note.getNotedAt(),
                note.getContent(),
                note.getCreatedAt(),
                note.getUpdatedAt()
        );
    }
}
