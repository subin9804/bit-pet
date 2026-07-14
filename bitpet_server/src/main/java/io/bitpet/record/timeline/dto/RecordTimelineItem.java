package io.bitpet.record.timeline.dto;

import io.bitpet.record.calendar.dto.RecordCategory;

import java.time.Instant;
import java.util.List;

public record RecordTimelineItem(
        RecordCategory category,
        Long recordId,
        Instant loggedAt,
        String summary,
        String routineTitle, // 루틴 완료로 생성된 기록이면 해당 루틴 제목 (수동 기록은 null)
        List<String> tags,   // MEMO 카테고리만
        String detailUrl
) {}
