package io.bitpet.record.controller;

import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * @deprecated v5에서 410 Gone 처리.
 * 대체: /api/v1/pets/{petId}/memos 사용
 */
@Tag(name = "HealthLog (Deprecated)", description = "⚠️ 410 Gone — /api/v1/pets/{petId}/memos 로 이전")
@RestController
@Deprecated
public class HealthLogController {

    private static final ApiResponse<Void> GONE_RESPONSE = ApiResponse.fail(
            io.bitpet.common.exception.ErrorCode.HEALTH_LOG_NOT_FOUND,
            "이 엔드포인트는 더 이상 지원되지 않습니다. /api/v1/pets/{petId}/memos 를 사용하세요."
    );

    @Operation(summary = "⚠️ Deprecated — 410 Gone")
    @GetMapping("/api/v1/pets/{petId}/health-logs")
    @ResponseStatus(HttpStatus.GONE)
    public ApiResponse<Void> list(@PathVariable Long petId) {
        return GONE_RESPONSE;
    }

    @Operation(summary = "⚠️ Deprecated — 410 Gone")
    @PostMapping("/api/v1/pets/{petId}/health-logs")
    @ResponseStatus(HttpStatus.GONE)
    public ApiResponse<Void> create(@PathVariable Long petId, @RequestBody Object ignored) {
        return GONE_RESPONSE;
    }

    @Operation(summary = "⚠️ Deprecated — 410 Gone")
    @PatchMapping("/api/v1/health-logs/{logId}")
    @ResponseStatus(HttpStatus.GONE)
    public ApiResponse<Void> update(@PathVariable Long logId, @RequestBody Object ignored) {
        return GONE_RESPONSE;
    }

    @Operation(summary = "⚠️ Deprecated — 410 Gone")
    @DeleteMapping("/api/v1/health-logs/{logId}")
    @ResponseStatus(HttpStatus.GONE)
    public ApiResponse<Void> delete(@PathVariable Long logId) {
        return GONE_RESPONSE;
    }
}
