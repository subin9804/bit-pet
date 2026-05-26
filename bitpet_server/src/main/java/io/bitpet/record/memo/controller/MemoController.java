package io.bitpet.record.memo.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.memo.dto.MemoCreateRequest;
import io.bitpet.record.memo.dto.MemoListResponse;
import io.bitpet.record.memo.dto.MemoResponse;
import io.bitpet.record.memo.dto.MemoTagResponse;
import io.bitpet.record.memo.dto.MemoUpdateRequest;
import io.bitpet.record.memo.service.MemoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@Tag(name = "Memo", description = "메모 기록 CRUD — /pets/:id/memos (v1 health-logs 대체)")
@RestController
@RequiredArgsConstructor
public class MemoController {

    private final MemoService memoService;

    @Operation(summary = "메모 목록 조회")
    @GetMapping("/api/v1/pets/{petId}/memos")
    public ApiResponse<MemoListResponse> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestParam(required = false) List<String> tags,
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {

        Pageable pageable = PageRequest.of(page, Math.min(size, 100));
        return ApiResponse.ok(memoService.getMemos(petId, principal.userId(), tags, from, to, pageable));
    }

    @Operation(summary = "메모 등록")
    @PostMapping("/api/v1/pets/{petId}/memos")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MemoResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody MemoCreateRequest request) {
        return ApiResponse.ok(memoService.createMemo(petId, principal.userId(), request));
    }

    @Operation(summary = "메모 단건 조회")
    @GetMapping("/api/v1/memos/{memoId}")
    public ApiResponse<MemoResponse> get(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long memoId) {
        return ApiResponse.ok(memoService.getMemo(memoId, principal.userId()));
    }

    @Operation(summary = "메모 수정 (전체 교체)")
    @PutMapping("/api/v1/memos/{memoId}")
    public ApiResponse<MemoResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long memoId,
            @Valid @RequestBody MemoUpdateRequest request) {
        return ApiResponse.ok(memoService.updateMemo(memoId, principal.userId(), request));
    }

    @Operation(summary = "메모 삭제")
    @DeleteMapping("/api/v1/memos/{memoId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long memoId) {
        memoService.deleteMemo(memoId, principal.userId());
        return ApiResponse.ok();
    }

    @Operation(summary = "메모 태그 코드 목록 (인증 불필요)")
    @GetMapping("/api/v1/memo-tags")
    public ApiResponse<List<MemoTagResponse>> tags() {
        return ApiResponse.ok(memoService.getTagList());
    }
}
