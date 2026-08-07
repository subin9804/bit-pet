package io.bitpet.nfc.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.nfc.service.NfcTagService;
import io.bitpet.pet.domain.PetMst;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 태그 재고 생산·출고용. 발급된 코드를 NFC Tools 로 NTAG213 에 굽고 재고로 보관한다.
 *
 * <p>이름표에 개체 이름을 각인해 파는 구조라 <b>어느 태그가 어느 개체용인지는 주문 시점에 정해진다.</b>
 * 그래서 출고 전에 {@code /bindings} 로 미리 붙여 두고, 고객은 받아서 찍기만 하면 된다.
 * (앱에서 고객이 직접 붙이는 경로도 살아 있다 — 미연결로 나간 재고와 연결 실패에 대비한다.)
 *
 * <p><b>모든 메서드가 {@link AdminGuard} 를 직접 통과시킨다.</b> SecurityConfig 는
 * {@code anyRequest().authenticated()} 뿐이라 URL 만으로는 이 컨트롤러가 보호되지 않는다 —
 * 가드를 빠뜨리면 로그인한 아무나 재고를 찍어내거나 남의 태그를 영구 차단할 수 있다.
 */
@Tag(name = "Admin - NFC Tag", description = "태그 재고 발급·출고 연결·통계")
@RestController
@RequestMapping("/api/v1/admin/tags")
@RequiredArgsConstructor
@Validated
public class NfcTagAdminController {

    private final NfcTagService nfcTagService;
    private final AdminGuard adminGuard;

    @Operation(summary = "재고 태그 코드 발급 — 반환된 코드를 태그에 굽는다",
            description = "batchNo 는 불량 회수 단위. 한 번에 굽는 묶음마다 다른 값을 주면 배치 통째로 차단할 수 있다.")
    @PostMapping("/issue")
    public List<String> issue(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam @Min(1) @Max(1000) int count,
            @RequestParam(required = false) String chipType,
            @RequestParam(required = false) String batchNo) {
        adminGuard.assertAdmin(principal.userId());
        return nfcTagService.issueStock(count, chipType, batchNo);
    }

    @Operation(summary = "주문 건 사전 연결 — 각인한 이름표를 출고 전에 개체에 붙인다",
            description = "사육자 검증 없이 붙는다. 태그 소유자는 개체의 소유자로 달리고, 이력에는 실행한 어드민이 남는다.")
    @PostMapping("/bindings")
    public Map<String, Object> bind(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam @NotBlank String tagCd,
            @RequestParam @NotNull Long petId) {
        adminGuard.assertAdmin(principal.userId());
        PetMst pet = nfcTagService.bindByAdmin(principal.userId(), tagCd, petId);
        return Map.of("tagCd", tagCd.trim().toUpperCase(),
                "petId", pet.getId(),
                "petName", pet.getName());
    }

    @Operation(summary = "태그 영구 차단 — 분실·복제 사고. 되돌릴 수 없다")
    @PostMapping("/revoke")
    public Map<String, Integer> revoke(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam List<String> tagCds) {
        adminGuard.assertAdmin(principal.userId());
        return Map.of("revokedCount", nfcTagService.revoke(tagCds));
    }

    @Operation(summary = "배치 단위 회수 — 불량 생산분 통째로 차단")
    @PostMapping("/revoke-batch")
    public Map<String, Integer> revokeBatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam String batchNo) {
        adminGuard.assertAdmin(principal.userId());
        return Map.of("revokedCount", nfcTagService.revokeBatch(batchNo));
    }

    @Operation(summary = "재고 통계 — unsold(미판매) / linked(연결됨) / released(해제됨) / revoked(차단됨)")
    @GetMapping("/stats")
    public Map<String, Long> stats(@AuthenticationPrincipal AuthPrincipal principal) {
        adminGuard.assertAdmin(principal.userId());
        return nfcTagService.stockStats();
    }
}
