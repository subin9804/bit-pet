package io.bitpet.nfc.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.nfc.domain.TagActionCd;
import io.bitpet.nfc.dto.MyTagResponse;
import io.bitpet.nfc.dto.TagLinkRequest;
import io.bitpet.nfc.dto.TagResolveResponse;
import io.bitpet.nfc.service.NfcTagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "NFC Tag", description = "NFC 태그 이름표 — 스캔 조회·개체 연결·해제")
@RestController
@RequestMapping("/api/v1/tags")
@RequiredArgsConstructor
public class NfcTagController {

    private final NfcTagService nfcTagService;

    @Operation(summary = "내가 연결한 태그 목록 (마이페이지 태그 관리)")
    @GetMapping("/my")
    public ApiResponse<List<MyTagResponse>> listMy(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(nfcTagService.listMyTags(principal.userId()));
    }

    @Operation(summary = "태그 조회 — UNLINKED / LINKED / OWNED_BY_OTHER 로 분기. 없는 코드는 404")
    @GetMapping("/{tagCd}")
    public ApiResponse<TagResolveResponse> resolve(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable String tagCd) {
        return ApiResponse.ok(nfcTagService.resolve(principal.userId(), tagCd));
    }

    @Operation(summary = "태그를 개체에 연결 (개체 소유자만). 남이 쓰는 태그면 409")
    @PostMapping("/{tagCd}/link")
    public ApiResponse<TagResolveResponse> link(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable String tagCd,
            @Valid @RequestBody TagLinkRequest request) {
        return ApiResponse.ok(nfcTagService.link(
                principal.userId(), tagCd, request.petId(), request.defaultActionCd()));
    }

    @Operation(summary = "태그 연결 해제 (태그 소유자만). 레코드는 남고 연결만 끊긴다")
    @DeleteMapping("/{tagCd}/link")
    public ApiResponse<Void> unlink(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable String tagCd) {
        nfcTagService.unlink(principal.userId(), tagCd);
        return ApiResponse.ok();
    }

    @Operation(summary = "태그 기본 동작 변경 (PET_DETAIL / RECORD_FEEDING / RECORD_WEIGHT)")
    @PatchMapping("/{tagCd}/action")
    public ApiResponse<MyTagResponse> updateAction(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable String tagCd,
            @RequestBody TagActionRequest request) {
        return ApiResponse.ok(nfcTagService.updateAction(
                principal.userId(), tagCd, request.defaultActionCd()));
    }

    public record TagActionRequest(TagActionCd defaultActionCd) {}
}
