package io.bitpet.record.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.dto.RecentRecordResponse;
import io.bitpet.record.service.RecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/records")
public class RecordController {

    private final RecordService recordService;

    @GetMapping("/recent")
    public ApiResponse<List<RecentRecordResponse>> getRecentRecords(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(defaultValue = "10") int limit) {
        return ApiResponse.ok(recordService.getRecentRecords(principal.userId(), limit));
    }
}
