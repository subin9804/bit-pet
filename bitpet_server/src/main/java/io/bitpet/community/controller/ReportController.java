package io.bitpet.community.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.dto.ReportCreateRequest;
import io.bitpet.community.dto.ReportReasonResponse;
import io.bitpet.community.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 신고 접수.
 *
 * <p>취소 API 가 <b>없는 것은 의도적이다</b> — 접수된 사건의 이력이라 지우면 "몇 번 신고당했는지"가
 * 사라진다. 마음이 바뀐 사용자는 차단만 해제하면 된다({@code DELETE /api/v1/blocks/{userId}}).
 */
@Tag(name = "Report", description = "커뮤니티 신고")
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @Operation(summary = "신고 사유 목록 — 앱의 사유 선택 시트가 이걸 그린다")
    @GetMapping("/reasons")
    public ApiResponse<List<ReportReasonResponse>> listReasons() {
        return ApiResponse.ok(reportService.listReasons());
    }

    @Operation(summary = "신고 접수 (작성자 자동 차단 동반)",
            description = "신고한 글이 계속 보이면 신고한 의미가 없으므로 작성자 차단이 함께 생성된다. "
                    + "차단만 하고 싶으면 POST /api/v1/blocks 를 쓴다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Void> report(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody ReportCreateRequest request) {
        reportService.report(principal.userId(), request);
        return ApiResponse.ok();
    }
}
