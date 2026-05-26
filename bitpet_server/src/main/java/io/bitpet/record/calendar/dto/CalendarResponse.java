package io.bitpet.record.calendar.dto;

import java.util.List;

public record CalendarResponse(
        Long petId,
        String yearMonth,
        List<CalendarDayDto> days
) {}
