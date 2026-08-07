package io.bitpet.nfc.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.nfc.dto.NfcScanResponse;
import io.bitpet.nfc.dto.TagBindRequest;
import io.bitpet.nfc.service.NfcTagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * NFC 스캔·바인딩.
 *
 * <p>구 {@code /api/v1/tags} 와 갈라둔 이유는 응답 모양이 다르기 때문이다. 여기서는 개체 카드를
 * 함께 내려준다 — 스캔 시트가 개체 상세를 다시 부르지 않고 그 자리에서 확인시켜야 해서다.
 * 구 경로는 태그 관리 화면(목록·해제)이 계속 쓴다.
 */
@Tag(name = "NFC Scan", description = "NFC 태그 스캔 조회 · 개체 바인딩")
@RestController
@RequestMapping("/api/v1/nfc")
@RequiredArgsConstructor
public class NfcScanController {

    private final NfcTagService nfcTagService;

    @Operation(summary = "태그 스캔 — 상태 + 개체 카드. 남의 개체면 소유자 정보를 뺀 카드만 내려간다")
    @GetMapping("/tags/{tagCd}/resolve")
    public ApiResponse<NfcScanResponse> resolve(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable String tagCd) {
        return ApiResponse.ok(nfcTagService.scan(principal.userId(), tagCd));
    }

    @Operation(summary = "태그를 개체에 바인딩 (개체 소유자만). 내 다른 개체에 붙어 있으면 409 후 rebind=true 로 재요청")
    @PostMapping("/bindings")
    public ApiResponse<NfcScanResponse> bind(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody TagBindRequest request) {
        nfcTagService.bind(principal.userId(), request.tagCd(), request.petId(), request.rebind());
        // 바인딩 직후 화면이 필요로 하는 건 결국 스캔 결과와 같은 모양이다
        return ApiResponse.ok(nfcTagService.scan(principal.userId(), request.tagCd()));
    }
}
