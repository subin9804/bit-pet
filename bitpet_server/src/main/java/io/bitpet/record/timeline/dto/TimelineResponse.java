package io.bitpet.record.timeline.dto;

import java.util.List;

public record TimelineResponse(
        List<RecordTimelineItem> items,
        int totalElements
) {}
