package io.bitpet.record.timeline.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.calendar.dto.RecordCategory;
import io.bitpet.record.timeline.dto.TimelineResponse;
import io.bitpet.record.timeline.service.TimelineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@Tag(name = "Timeline", description = "개체별 통합 타임라인 (전 카테고리 시계열)")
@RestController
@RequiredArgsConstructor
public class TimelineController {

    private final TimelineService timelineService;

    @Operation(summary = "통합 타임라인 조회")
    @GetMapping("/api/v1/pets/{petId}/records")
    public ApiResponse<TimelineResponse> getTimeline(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestParam(required = false) LocalDate date,
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to,
            @RequestParam(required = false) List<RecordCategory> categories,
            @RequestParam(required = false) Integer limit) {
        return ApiResponse.ok(timelineService.getTimeline(
                petId, principal.userId(), date, from, to, categories, limit));
    }
}
