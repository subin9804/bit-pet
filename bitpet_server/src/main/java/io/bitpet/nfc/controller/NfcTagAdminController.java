package io.bitpet.nfc.controller;

import io.bitpet.nfc.service.NfcTagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 태그 재고 생산용. 발급된 코드를 NFC Tools 로 NTAG213 에 굽고 재고로 보관한다.
 *
 * <p>어느 태그가 어느 개체에 연결될지는 출고 시점에 알 필요가 없다 — 유저가 앱에서 직접 연결한다.
 */
@Tag(name = "Admin - NFC Tag", description = "태그 재고 발급·통계")
@RestController
@RequestMapping("/api/v1/admin/tags")
@RequiredArgsConstructor
@Validated
public class NfcTagAdminController {

    private final NfcTagService nfcTagService;

    @Operation(summary = "재고 태그 코드 발급 — 반환된 코드를 태그에 굽는다",
            description = "batchNo 는 불량 회수 단위. 한 번에 굽는 묶음마다 다른 값을 주면 배치 통째로 차단할 수 있다.")
    @PostMapping("/issue")
    public List<String> issue(
            @RequestParam @Min(1) @Max(1000) int count,
            @RequestParam(required = false) String chipType,
            @RequestParam(required = false) String batchNo) {
        return nfcTagService.issueStock(count, chipType, batchNo);
    }

    @Operation(summary = "태그 영구 차단 — 분실·복제 사고. 되돌릴 수 없다")
    @PostMapping("/revoke")
    public Map<String, Integer> revoke(@RequestParam List<String> tagCds) {
        return Map.of("revokedCount", nfcTagService.revoke(tagCds));
    }

    @Operation(summary = "배치 단위 회수 — 불량 생산분 통째로 차단")
    @PostMapping("/revoke-batch")
    public Map<String, Integer> revokeBatch(@RequestParam String batchNo) {
        return Map.of("revokedCount", nfcTagService.revokeBatch(batchNo));
    }

    @Operation(summary = "재고 통계 — unsold(미판매) / linked(연결됨) / released(해제됨) / revoked(차단됨)")
    @GetMapping("/stats")
    public Map<String, Long> stats() {
        return nfcTagService.stockStats();
    }
}
