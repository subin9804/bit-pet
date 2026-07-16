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
import io.bitpet.pet.share.dto.BulkShareInviteRequest;
import io.bitpet.pet.share.dto.KeeperResponse;
import io.bitpet.pet.share.dto.ShareCodeResponse;
import io.bitpet.pet.share.dto.ShareInvitationBatchResponse;
import io.bitpet.pet.share.dto.ShareInviteRequest;
import io.bitpet.pet.share.dto.ShareInvitationResponse;
import io.bitpet.pet.share.repository.PetShareInvitationRepository;
import io.bitpet.routine.service.RoutineMaintenanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

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
                .batchId(UUID.randomUUID())   // 단건도 고유 배치 1건
                .build());
        return toResponse(saved);
    }

    /**
     * 여러 개체를 한 번에 초대 (같은 batch_id 공유).
     * - 소유권 검증: petIds 중 하나라도 소유자가 아니면 403 (전체 실패)
     * - 이미 사육자(SHARE)이거나 대기중인 개체는 건너뜀
     * - 유효한 개체가 하나도 없으면 SHARE_BULK_NO_VALID_PET
     */
    @Transactional
    public ShareInvitationBatchResponse inviteBulk(Long ownerUserId, BulkShareInviteRequest req) {
        UserMst invitee = userRepository.findByShareCode(req.shareCode().toUpperCase())
                .orElseThrow(() -> new BusinessException(ErrorCode.SHARE_CODE_INVALID));
        if (invitee.getId().equals(ownerUserId)) {
            throw new BusinessException(ErrorCode.SHARE_SELF);
        }

        UUID batchId = UUID.randomUUID();
        List<PetShareInvitation> created = new ArrayList<>();
        for (Long petId : new LinkedHashSet<>(req.petIds())) {   // 중복 제거, 순서 보존
            petKeeper.assertOwner(ownerUserId, petId);           // 소유권 — 하나라도 아니면 403

            if (req.inviteType() == ShareInviteType.SHARE
                    && keeperRepository.existsByIdPetIdAndIdUserId(petId, invitee.getId())) {
                continue;   // 이미 사육자 — 건너뜀
            }
            if (invitationRepository.findByPetIdAndInviteeUserIdAndStatus(
                    petId, invitee.getId(), ShareInviteStatus.PENDING).isPresent()) {
                continue;   // 이미 대기중 — 건너뜀
            }
            created.add(invitationRepository.save(PetShareInvitation.builder()
                    .petId(petId)
                    .inviterUserId(ownerUserId)
                    .inviteeUserId(invitee.getId())
                    .inviteType(req.inviteType())
                    .batchId(batchId)
                    .build()));
        }
        if (created.isEmpty()) {
            throw new BusinessException(ErrorCode.SHARE_BULK_NO_VALID_PET);
        }
        return toBatchResponse(created);
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

    /** 내가 받은 대기중 초대함 — batch_id 로 묶어 반환 (최신 배치 우선) */
    @Transactional
    public List<ShareInvitationBatchResponse> listReceivedBatches(Long userId) {
        List<PetShareInvitation> pending = invitationRepository
                .findAllByInviteeUserIdAndStatusOrderByCreatedAtDesc(userId, ShareInviteStatus.PENDING)
                .stream()
                .filter(this::keepIfNotExpired)
                .toList();
        // createdAt desc 순서 보존하며 batch_id 로 그룹핑
        Map<UUID, List<PetShareInvitation>> byBatch = new LinkedHashMap<>();
        for (PetShareInvitation inv : pending) {
            byBatch.computeIfAbsent(inv.getBatchId(), k -> new ArrayList<>()).add(inv);
        }
        return byBatch.values().stream().map(this::toBatchResponse).toList();
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
        applyAccept(inv);
    }

    @Transactional
    public void reject(Long userId, Long invitationId) {
        PetShareInvitation inv = loadPendingForInvitee(userId, invitationId);
        inv.reject();
    }

    /** 배치 전체 수락 — 만료된 건은 EXPIRED 처리 후 건너뜀 */
    @Transactional
    public void acceptBatch(Long userId, UUID batchId) {
        List<PetShareInvitation> items = invitationRepository
                .findAllByBatchIdAndInviteeUserIdAndStatus(batchId, userId, ShareInviteStatus.PENDING);
        if (items.isEmpty()) {
            throw new BusinessException(ErrorCode.SHARE_INVITATION_NOT_FOUND);
        }
        for (PetShareInvitation inv : items) {
            if (inv.isExpired()) {
                inv.expire();
                continue;
            }
            applyAccept(inv);
        }
    }

    /** 배치 전체 거절 */
    @Transactional
    public void rejectBatch(Long userId, UUID batchId) {
        List<PetShareInvitation> items = invitationRepository
                .findAllByBatchIdAndInviteeUserIdAndStatus(batchId, userId, ShareInviteStatus.PENDING);
        if (items.isEmpty()) {
            throw new BusinessException(ErrorCode.SHARE_INVITATION_NOT_FOUND);
        }
        for (PetShareInvitation inv : items) {
            inv.reject();
        }
    }

    /** 단건 수락 실행 (accept/acceptBatch 공용) */
    private void applyAccept(PetShareInvitation inv) {
        Long inviteeUserId = inv.getInviteeUserId();
        if (inv.getInviteType() == ShareInviteType.TRANSFER) {
            transferOwnership(inv.getPetId(), inv.getInviterUserId(), inviteeUserId);
        } else {
            // SHARE — 이미 사육자가 아니면 KEEPER 추가
            if (!keeperRepository.existsByIdPetIdAndIdUserId(inv.getPetId(), inviteeUserId)) {
                petKeeper.registerKeeper(inv.getPetId(), inviteeUserId);
            }
        }
        inv.accept();
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
        String petName = petName(inv.getPetId());
        String inviterName = userName(inv.getInviterUserId());
        String inviteeName = userName(inv.getInviteeUserId());
        return ShareInvitationResponse.of(inv, petName, inviterName, inviteeName);
    }

    private ShareInvitationBatchResponse toBatchResponse(List<PetShareInvitation> items) {
        PetShareInvitation head = items.get(0);
        String inviterName = userName(head.getInviterUserId());
        String inviteeName = userName(head.getInviteeUserId());
        return ShareInvitationBatchResponse.of(items, this::petName, inviterName, inviteeName);
    }

    private String petName(Long petId) {
        return petRepository.findById(petId).map(PetMst::getName).orElse(null);
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
