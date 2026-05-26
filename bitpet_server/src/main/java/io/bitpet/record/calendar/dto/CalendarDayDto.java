package io.bitpet.record.calendar.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public record CalendarDayDto(
        LocalDate date,
        List<String> categories,
        Map<String, Integer> counts
) {}
