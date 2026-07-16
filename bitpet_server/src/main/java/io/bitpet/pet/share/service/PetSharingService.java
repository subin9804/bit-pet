package io.bitpet.pet.share.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.pet.share.domain.PetShareInvitation;
import io.bitpet.pet.share.domain.ShareInviteStatus;
import io.bitpet.pet.share.domain.ShareInviteType;
import io.bitpet.pet.share.dto.KeeperResponse;
import io.bitpet.pet.share.dto.ShareCodeResponse;
import io.bitpet.pet.share.dto.ShareInviteRequest;
import io.bitpet.pet.share.dto.ShareInvitationResponse;
import io.bitpet.pet.share.repository.PetShareInvitationRepository;
import io.bitpet.routine.service.RoutineMaintenanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 개체 공유(SHARE)·입분양(TRANSFER) 초대 처리.
 * - SHARE   : 대상이 KEEPER로 추가됨 (소유자 유지)
 * - TRANSFER: 대상이 OWNER로 승격, 기존 소유자는 KEEPER로 강등 (기록 접근 유지)
 * 수락·입분양은 단일 @Transactional로 처리한다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetSharingService {

    private final PetMstRepository petRepository;
    private final UserMstRepository userRepository;
    private final PetKeeperRlsRepository keeperRepository;
    private final PetShareInvitationRepository invitationRepository;
    private final PetKeeperService petKeeper;
    private final RoutineMaintenanceService routineMaintenance;
    private final ShareCodeGenerator shareCodeGenerator;

    // -------------------------------------------------------------------------
    // 초대 보내기 (소유자 전용)
    // -------------------------------------------------------------------------

    @Transactional
    public ShareInvitationResponse invite(Long ownerUserId, Long petId, ShareInviteRequest req) {
        petKeeper.assertOwner(ownerUserId, petId);

        UserMst invitee = userRepository.findByShareCode(req.shareCode().toUpperCase())
                .orElseThrow(() -> new BusinessException(ErrorCode.SHARE_CODE_INVALID));
        if (invitee.getId().equals(ownerUserId)) {
            throw new BusinessException(ErrorCode.SHARE_SELF);
        }
        // SHARE: 이미 사육자면 중복 (TRANSFER는 기존 사육자 대상도 허용 — 소유권 이전)
        if (req.inviteType() == ShareInviteType.SHARE
                && keeperRepository.existsByIdPetIdAndIdUserId(petId, invitee.getId())) {
            throw new BusinessException(ErrorCode.SHARE_ALREADY_KEEPER);
        }
        invitationRepository.findByPetIdAndInviteeUserIdAndStatus(
                        petId, invitee.getId(), ShareInviteStatus.PENDING)
                .ifPresent(inv -> { throw new BusinessException(ErrorCode.SHARE_INVITATION_ALREADY_PENDING); });

        PetShareInvitation saved = invitationRepository.save(PetShareInvitation.builder()
                .petId(petId)
                .inviterUserId(ownerUserId)
                .inviteeUserId(invitee.getId())
                .inviteType(req.inviteType())
                .build());
        return toResponse(saved);
    }

    // -------------------------------------------------------------------------
    // 초대 조회
    // -------------------------------------------------------------------------

    /** 내가 받은 대기중 초대함 (조회 시 만료분은 EXPIRED 전환 후 제외) */
    @Transactional
    public List<ShareInvitationResponse> listReceived(Long userId) {
        return invitationRepository
                .findAllByInviteeUserIdAndStatusOrderByCreatedAtDesc(userId, ShareInviteStatus.PENDING)
                .stream()
                .filter(this::keepIfNotExpired)
                .map(this::toResponse).toList();
    }

    /** 특정 개체에 대해 내가 보낸 대기중 초대 (소유자 전용, 만료분은 EXPIRED 전환 후 제외) */
    @Transactional
    public List<ShareInvitationResponse> listSent(Long ownerUserId, Long petId) {
        petKeeper.assertOwner(ownerUserId, petId);
        return invitationRepository
                .findAllByPetIdAndStatusOrderByCreatedAtDesc(petId, ShareInviteStatus.PENDING)
                .stream()
                .filter(this::keepIfNotExpired)
                .map(this::toResponse).toList();
    }

    /** 만료됐으면 EXPIRED로 전환하고 목록에서 제외(false), 아니면 유지(true) */
    private boolean keepIfNotExpired(PetShareInvitation inv) {
        if (inv.isExpired()) {
            inv.expire();
            return false;
        }
        return true;
    }

    // -------------------------------------------------------------------------
    // 초대 응답 (받은 사람)
    // -------------------------------------------------------------------------

    @Transactional
    public void accept(Long userId, Long invitationId) {
        PetShareInvitation inv = loadPendingForInvitee(userId, invitationId);

        if (inv.getInviteType() == ShareInviteType.TRANSFER) {
            transferOwnership(inv.getPetId(), inv.getInviterUserId(), userId);
        } else {
            // SHARE — 이미 사육자가 아니면 KEEPER 추가
            if (!keeperRepository.existsByIdPetIdAndIdUserId(inv.getPetId(), userId)) {
                petKeeper.registerKeeper(inv.getPetId(), userId);
            }
        }
        inv.accept();
    }

    @Transactional
    public void reject(Long userId, Long invitationId) {
        PetShareInvitation inv = loadPendingForInvitee(userId, invitationId);
        inv.reject();
    }

    // -------------------------------------------------------------------------
    // 초대 취소 (보낸 사람 = 소유자)
    // -------------------------------------------------------------------------

    @Transactional
    public void cancel(Long ownerUserId, Long invitationId) {
        PetShareInvitation inv = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SHARE_INVITATION_NOT_FOUND));
        if (!inv.getInviterUserId().equals(ownerUserId)) {
            throw new BusinessException(ErrorCode.SHARE_INVITATION_FORBIDDEN);
        }
        if (!inv.isPending()) {
            throw new BusinessException(ErrorCode.SHARE_INVITATION_NOT_PENDING);
        }
        inv.cancel();
    }

    // -------------------------------------------------------------------------
    // 사육자(공유 멤버) 목록·해제
    // -------------------------------------------------------------------------

    /** 개체의 사육자 목록 — 사육자면 조회 가능 */
    public List<KeeperResponse> listKeepers(Long userId, Long petId) {
        petKeeper.assertKeeper(userId, petId);
        return keeperRepository.findAllByIdPetId(petId).stream()
                .map(this::toKeeperResponse)
                .sorted(java.util.Comparator.comparing(KeeperResponse::joinedAt))
                .toList();
    }

    /** 공유 해제 — 소유자가 KEEPER를 내보냄 */
    @Transactional
    public void revokeKeeper(Long ownerUserId, Long petId, Long keeperUserId) {
        petKeeper.assertOwner(ownerUserId, petId);
        if (ownerUserId.equals(keeperUserId)) {
            // 소유자 자신은 이 API로 제거 불가 (입분양/삭제로만)
            throw new BusinessException(ErrorCode.SHARE_INVITATION_FORBIDDEN);
        }
        keeperRepository.findByIdPetIdAndIdUserId(petId, keeperUserId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SHARE_INVITATION_NOT_FOUND));
        keeperRepository.deleteByIdPetIdAndIdUserId(petId, keeperUserId);
        // 내보낸 사육자의 루틴에서 이 개체 연결 제거 + 활성 재계산
        routineMaintenance.onKeeperAccessLost(keeperUserId, petId);
    }

    /** 내가 공유받은 개체에서 스스로 나가기 (KEEPER 자진 해제) */
    @Transactional
    public void leave(Long userId, Long petId) {
        PetKeeperRls me = keeperRepository.findByIdPetIdAndIdUserId(petId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_ACCESS_DENIED));
        if (me.isOwner()) {
            // 소유자는 나갈 수 없음 (입분양/삭제로만)
            throw new BusinessException(ErrorCode.SHARE_INVITATION_FORBIDDEN);
        }
        keeperRepository.deleteByIdPetIdAndIdUserId(petId, userId);
        routineMaintenance.onKeeperAccessLost(userId, petId);
    }

    // -------------------------------------------------------------------------
    // 내 공유코드
    // -------------------------------------------------------------------------

    @Transactional
    public ShareCodeResponse myShareCode(Long userId) {
        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));
        if (user.getShareCode() == null || user.getShareCode().isBlank()) {
            user.assignShareCode(shareCodeGenerator.generateUnique());
        }
        return new ShareCodeResponse(user.getShareCode());
    }

    // -------------------------------------------------------------------------
    // 소유권 이전 (입분양) — TRANSFER 수락 시 단일 트랜잭션
    // -------------------------------------------------------------------------

    private void transferOwnership(Long petId, Long oldOwnerUserId, Long newOwnerUserId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));

        // 기존 소유자 → KEEPER 강등 (기록 접근 유지)
        keeperRepository.findByIdPetIdAndIdUserId(petId, oldOwnerUserId)
                .ifPresent(old -> keeperRepository.delete(old));
        keeperRepository.save(PetKeeperRls.of(petId, oldOwnerUserId,
                io.bitpet.pet.domain.PetKeeperRole.KEEPER));

        // 새 소유자 → OWNER (기존 KEEPER 행이 있으면 교체)
        keeperRepository.findByIdPetIdAndIdUserId(petId, newOwnerUserId)
                .ifPresent(k -> keeperRepository.delete(k));
        keeperRepository.save(PetKeeperRls.of(petId, newOwnerUserId,
                io.bitpet.pet.domain.PetKeeperRole.OWNER));

        // 비정규화된 소유자 포인터 동기화
        pet.transferOwnerTo(newOwnerUserId);
    }

    // -------------------------------------------------------------------------
    // helpers
    // -------------------------------------------------------------------------

    private PetShareInvitation loadPendingForInvitee(Long userId, Long invitationId) {
        PetShareInvitation inv = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SHARE_INVITATION_NOT_FOUND));
        if (!inv.getInviteeUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.SHARE_INVITATION_FORBIDDEN);
        }
        if (!inv.isPending()) {
            throw new BusinessException(ErrorCode.SHARE_INVITATION_NOT_PENDING);
        }
        // Lazy 만료 판정 — 배치 지연 대비, 응답 시점에 재검증
        if (inv.isExpired()) {
            inv.expire();
            throw new BusinessException(ErrorCode.SHARE_INVITATION_EXPIRED);
        }
        return inv;
    }

    private ShareInvitationResponse toResponse(PetShareInvitation inv) {
        String petName = petRepository.findById(inv.getPetId())
                .map(PetMst::getName).orElse(null);
        String inviterName = userName(inv.getInviterUserId());
        String inviteeName = userName(inv.getInviteeUserId());
        return ShareInvitationResponse.of(inv, petName, inviterName, inviteeName);
    }

    private KeeperResponse toKeeperResponse(PetKeeperRls k) {
        UserMst u = userRepository.findById(k.getUserId()).orElse(null);
        return new KeeperResponse(
                k.getUserId(),
                u != null ? u.getName() : null,
                u != null ? u.getProfileImageUrl() : null,
                k.getRole(),
                k.getJoinedAt());
    }

    private String userName(Long userId) {
        return userRepository.findById(userId).map(UserMst::getName).orElse(null);
    }
}
