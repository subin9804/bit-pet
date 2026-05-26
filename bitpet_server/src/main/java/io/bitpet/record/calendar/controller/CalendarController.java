package io.bitpet.record.calendar.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.calendar.dto.CalendarResponse;
import io.bitpet.record.calendar.dto.RecordCategory;
import io.bitpet.record.calendar.service.CalendarService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Calendar", description = "개체별 월별 캘린더 집계")
@RestController
@RequiredArgsConstructor
public class CalendarController {

    private final CalendarService calendarService;

    @Operation(summary = "개체 월별 캘린더 조회 (yearMonth=YYYY-MM)")
    @GetMapping("/api/v1/pets/{petId}/calendar")
    public ApiResponse<CalendarResponse> getCalendar(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestParam(required = false) String yearMonth,
            @RequestParam(required = false) List<RecordCategory> categories) {
        return ApiResponse.ok(calendarService.getCalendar(petId, principal.userId(), yearMonth, categories));
    }
}
