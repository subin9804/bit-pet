package io.bitpet.pet.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.dto.UserProfileResponse;
import io.bitpet.pet.service.PetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 공개 프로필 — 가계도 카드의 '@닉네임'을 눌렀을 때 들어오는 화면.
 * 개체 중심 응답이라 pet 패키지에 둔다(내용이 그 사람의 공개 개체 목록이다).
 */
@Tag(name = "User Profile", description = "공개 프로필 (가계도 소유자 표시)")
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserProfileController {

    private final PetService petService;

    @Operation(summary = "공개 프로필 조회 (닉네임 + 공개 개체 목록)")
    @GetMapping("/{userId}/profile")
    public ApiResponse<UserProfileResponse> getProfile(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long userId) {
        return ApiResponse.ok(petService.getUserProfile(principal.userId(), userId));
    }
}
