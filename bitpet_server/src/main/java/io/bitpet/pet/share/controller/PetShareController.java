package io.bitpet.pet.share.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.share.dto.BulkShareInviteRequest;
import io.bitpet.pet.share.dto.KeeperResponse;
import io.bitpet.pet.share.dto.ShareCodeResponse;
import io.bitpet.pet.share.dto.ShareInvitationBatchResponse;
import io.bitpet.pet.share.dto.ShareInviteRequest;
import io.bitpet.pet.share.dto.ShareInvitationResponse;
import io.bitpet.pet.share.service.PetSharingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Pet Share", description = "개체 공유·입분양 (pet_keeper_rls 기반)")
@RestController
@RequestMapping("/api/v1/pets")
@RequiredArgsConstructor
public class PetShareController {

    private final PetSharingService sharingService;

    // --- 내 공유코드 ---

    @Operation(summary = "내 공유코드 조회 (없으면 발급)")
    @GetMapping("/share/my-code")
    public ApiResponse<ShareCodeResponse> myShareCode(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(sharingService.myShareCode(principal.userId()));
    }

    // --- 받은 초대함 ---

    @Operation(summary = "내가 받은 공유·입분양 초대 목록 (대기중)")
    @GetMapping("/share/invitations")
    public ApiResponse<List<ShareInvitationResponse>> received(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(sharingService.listReceived(principal.userId()));
    }

    @Operation(summary = "공유·입분양 초대 수락")
    @PostMapping("/share/invitations/{invitationId}/accept")
    public ApiResponse<Void> accept(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long invitationId) {
        sharingService.accept(principal.userId(), invitationId);
        return ApiResponse.ok();
    }

    @Operation(summary = "공유·입분양 초대 거절")
    @PostMapping("/share/invitations/{invitationId}/reject")
    public ApiResponse<Void> reject(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long invitationId) {
        sharingService.reject(principal.userId(), invitationId);
        return ApiResponse.ok();
    }

    @Operation(summary = "보낸 초대 취소 (소유자)")
    @PostMapping("/share/invitations/{invitationId}/cancel")
    public ApiResponse<Void> cancel(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long invitationId) {
        sharingService.cancel(principal.userId(), invitationId);
        return ApiResponse.ok();
    }

    // --- 벌크 초대 (여러 개체 한 번에) ---

    @Operation(summary = "여러 개체를 한 번에 공유·입분양 초대 (소유자)")
    @PostMapping("/share/bulk")
    public ApiResponse<ShareInvitationBatchResponse> inviteBulk(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody BulkShareInviteRequest request) {
        return ApiResponse.ok(sharingService.inviteBulk(principal.userId(), request));
    }

    @Operation(summary = "받은 초대함 — 배치(여러 개체)로 묶어 조회")
    @GetMapping("/share/invitations/batches")
    public ApiResponse<List<ShareInvitationBatchResponse>> receivedBatches(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(sharingService.listReceivedBatches(principal.userId()));
    }

    @Operation(summary = "배치 전체 수락 (받은 사람)")
    @PostMapping("/share/batches/{batchId}/accept")
    public ApiResponse<Void> acceptBatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable UUID batchId) {
        sharingService.acceptBatch(principal.userId(), batchId);
        return ApiResponse.ok();
    }

    @Operation(summary = "배치 전체 거절 (받은 사람)")
    @PostMapping("/share/batches/{batchId}/reject")
    public ApiResponse<Void> rejectBatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable UUID batchId) {
        sharingService.rejectBatch(principal.userId(), batchId);
        return ApiResponse.ok();
    }

    // --- 개체별 공유 관리 (소유자) ---

    @Operation(summary = "개체 공유·입분양 초대 보내기 (소유자)")
    @PostMapping("/{petId}/share")
    public ApiResponse<ShareInvitationResponse> invite(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody ShareInviteRequest request) {
        return ApiResponse.ok(sharingService.invite(principal.userId(), petId, request));
    }

    @Operation(summary = "개체에 대해 내가 보낸 대기중 초대 목록 (소유자)")
    @GetMapping("/{petId}/share/invitations")
    public ApiResponse<List<ShareInvitationResponse>> sent(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(sharingService.listSent(principal.userId(), petId));
    }

    @Operation(summary = "개체 사육자(공유 멤버) 목록")
    @GetMapping("/{petId}/keepers")
    public ApiResponse<List<KeeperResponse>> keepers(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(sharingService.listKeepers(principal.userId(), petId));
    }

    @Operation(summary = "공유 해제 — 사육자 내보내기 (소유자)")
    @DeleteMapping("/{petId}/keepers/{keeperUserId}")
    public ApiResponse<Void> revokeKeeper(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long keeperUserId) {
        sharingService.revokeKeeper(principal.userId(), petId, keeperUserId);
        return ApiResponse.ok();
    }

    @Operation(summary = "공유받은 개체에서 스스로 나가기 (KEEPER)")
    @DeleteMapping("/{petId}/keepers/me")
    public ApiResponse<Void> leave(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        sharingService.leave(principal.userId(), petId);
        return ApiResponse.ok();
    }
}
