package io.bitpet.group.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.group.dto.*;
import io.bitpet.group.service.BreedingGroupService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Group", description = "사육 그룹 API")
@RestController
@RequestMapping("/api/v1/groups")
@RequiredArgsConstructor
public class BreedingGroupController {

    private final BreedingGroupService groupService;

    @Operation(summary = "내 그룹 조회 (없으면 null)")
    @GetMapping("/me")
    public ApiResponse<GroupResponse> getMyGroup(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(
                groupService.findMyGroup(principal.userId()).orElse(null)
        );
    }

    @Operation(summary = "새 그룹 생성")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<GroupResponse> createGroup(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody GroupCreateRequest request) {
        return ApiResponse.ok(groupService.createGroup(principal.userId(), request.name()));
    }

    @Operation(summary = "5분간 유효한 임시 초대코드 발급 (OWNER 전용)")
    @PostMapping("/me/invite-code")
    public ApiResponse<InviteCodeResponse> issueInviteCode(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(groupService.issueInviteCode(principal.userId()));
    }

    @Operation(summary = "초대코드로 그룹 참여 (기존 그룹이 있으면 자동 처리)")
    @PostMapping("/join")
    public ApiResponse<GroupResponse> joinGroup(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody GroupJoinRequest request) {
        return ApiResponse.ok(groupService.joinGroup(principal.userId(), request.inviteCode()));
    }

    @Operation(summary = "그룹 이름 수정 (OWNER 전용)")
    @PatchMapping("/me/name")
    public ApiResponse<GroupResponse> updateGroupName(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody GroupUpdateRequest request) {
        return ApiResponse.ok(groupService.updateGroupName(principal.userId(), request.name()));
    }

    @Operation(summary = "그룹 탈퇴 (MEMBER) 또는 해산 (OWNER)")
    @DeleteMapping("/me")
    public ResponseEntity<ApiResponse<Void>> leaveOrDisband(
            @AuthenticationPrincipal AuthPrincipal principal) {
        groupService.leaveOrDisband(principal.userId());
        return ResponseEntity.noContent().<ApiResponse<Void>>build();
    }

    @Operation(summary = "멤버 강제 탈퇴 (OWNER 전용)")
    @DeleteMapping("/me/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> kickMember(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long userId) {
        groupService.kickMember(principal.userId(), userId);
        return ResponseEntity.noContent().<ApiResponse<Void>>build();
    }
}
