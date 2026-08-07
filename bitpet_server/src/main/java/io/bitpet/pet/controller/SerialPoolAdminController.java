package io.bitpet.pet.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.pet.dto.SerialPoolStatResponse;
import io.bitpet.pet.service.SerialPoolService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 일련번호 풀 운영용.
 *
 * <p>SecurityConfig 는 {@code anyRequest().authenticated()} 뿐이라 URL 만으로는
 * {@code /api/v1/admin/**} 이 보호되지 않는다. 가드를 직접 통과시킨다.
 */
@Tag(name = "Admin - Serial Pool")
@RestController
@RequestMapping("/api/v1/admin/serial-pool")
@RequiredArgsConstructor
public class SerialPoolAdminController {

    private final SerialPoolService serialPoolService;
    private final AdminGuard adminGuard;

    @GetMapping("/stats")
    public List<SerialPoolStatResponse> getStats(@AuthenticationPrincipal AuthPrincipal principal) {
        adminGuard.assertAdmin(principal.userId());
        return serialPoolService.listStats();
    }

    @PostMapping("/refresh")
    public SerialPoolStatResponse refresh(@AuthenticationPrincipal AuthPrincipal principal) {
        adminGuard.assertAdmin(principal.userId());
        return serialPoolService.forceRefresh();
    }
}
