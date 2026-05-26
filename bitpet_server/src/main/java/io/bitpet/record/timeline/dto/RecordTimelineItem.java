package io.bitpet.record.timeline.dto;

import io.bitpet.record.calendar.dto.RecordCategory;

import java.time.Instant;
import java.util.List;

public record RecordTimelineItem(
        RecordCategory category,
        Long recordId,
        Instant loggedAt,
        String summary,
        List<String> tags,   // MEMO 카테고리만
        String detailUrl
) {}
