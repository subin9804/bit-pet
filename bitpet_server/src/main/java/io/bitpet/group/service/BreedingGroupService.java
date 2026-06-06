package io.bitpet.group.service;

import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.group.domain.BreedingGroupMst;
import io.bitpet.group.domain.BreedingGroupUserRls;
import io.bitpet.group.domain.GroupRole;
import io.bitpet.group.dto.GroupMemberResponse;
import io.bitpet.group.dto.GroupResponse;
import io.bitpet.group.repository.BreedingGroupMstRepository;
import io.bitpet.group.repository.BreedingGroupUserRlsRepository;
import io.bitpet.pet.repository.PetMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BreedingGroupService {

    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int    CODE_LEN   = 6;
    private static final int    CODE_RETRY = 10;

    private final BreedingGroupMstRepository     groupRepo;
    private final BreedingGroupUserRlsRepository memberRepo;
    private final PetMstRepository               petRepo;
    private final UserMstRepository              userRepo;
    private final SecureRandom                   random = new SecureRandom();

    // ── 조회 ──────────────────────────────────────────────────────────

    /** 내 그룹 정보. 그룹이 없으면 Optional.empty() */
    public Optional<GroupResponse> findMyGroup(Long userId) {
        return memberRepo.findByIdUserId(userId).map(membership -> {
            BreedingGroupMst group = groupRepo.findById(membership.getGroupId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.GROUP_NOT_FOUND));
            return buildGroupResponse(group, membership.getRole());
        });
    }

    // ── 생성 ──────────────────────────────────────────────────────────

    /**
     * 새 그룹 생성.
     * 이미 그룹이 있으면 예외 (클라이언트가 선 탈퇴/해산 후 호출해야 함).
     */
    @Transactional
    public GroupResponse createGroup(Long userId, String name) {
        if (memberRepo.findByIdUserId(userId).isPresent()) {
            throw new BusinessException(ErrorCode.GROUP_ALREADY_JOINED);
        }

        String code   = generateUniqueCode();
        BreedingGroupMst group = BreedingGroupMst.builder()
                .name(name)
                .inviteCode(code)
                .ownerId(userId)
                .build();
        groupRepo.save(group);
        memberRepo.save(BreedingGroupUserRls.of(group.getId(), userId, GroupRole.OWNER));

        // 생성자의 개체를 새 그룹으로 이동
        petRepo.assignGroupToUserPets(userId, group.getId());

        return buildGroupResponse(group, GroupRole.OWNER);
    }

    // ── 참여 ──────────────────────────────────────────────────────────

    /**
     * 초대코드로 그룹 참여.
     * 기존 그룹이 있으면:
     *   - OWNER → 해당 그룹 해산 (멤버 전원 자동 탈퇴, 개체 group_id = NULL)
     *   - MEMBER → 해당 그룹에서 탈퇴
     */
    @Transactional
    public GroupResponse joinGroup(Long userId, String inviteCode) {
        BreedingGroupMst target = groupRepo.findByInviteCode(inviteCode.toUpperCase())
                .orElseThrow(() -> new BusinessException(ErrorCode.GROUP_INVITE_CODE_INVALID));

        // 이미 이 그룹에 속해 있으면 그냥 반환
        memberRepo.findByIdUserId(userId).ifPresent(existing -> {
            if (existing.getGroupId().equals(target.getId())) {
                throw new BusinessException(ErrorCode.GROUP_ALREADY_JOINED);
            }
            // 기존 그룹 처리
            if (existing.getRole() == GroupRole.OWNER) {
                disbandGroupInternal(existing.getGroupId());
            } else {
                petRepo.removeGroupFromUserPets(userId, existing.getGroupId());
                memberRepo.delete(existing);
            }
        });

        memberRepo.save(BreedingGroupUserRls.of(target.getId(), userId, GroupRole.MEMBER));
        petRepo.assignGroupToUserPets(userId, target.getId());

        return buildGroupResponse(target, GroupRole.MEMBER);
    }

    // ── 수정 ──────────────────────────────────────────────────────────

    @Transactional
    public GroupResponse updateGroupName(Long userId, String newName) {
        BreedingGroupUserRls membership = getOwnerMembership(userId);
        BreedingGroupMst group = groupRepo.findById(membership.getGroupId())
                .orElseThrow(() -> new BusinessException(ErrorCode.GROUP_NOT_FOUND));
        group.updateName(newName);
        return buildGroupResponse(group, GroupRole.OWNER);
    }

    // ── 탈퇴/해산 ────────────────────────────────────────────────────

    /**
     * 그룹 탈퇴 or 해산.
     * OWNER → 그룹 해산 (모든 멤버 탈퇴, 개체 group_id = NULL)
     * MEMBER → 탈퇴 (자신의 개체만 group_id = NULL)
     */
    @Transactional
    public void leaveOrDisband(Long userId) {
        BreedingGroupUserRls membership = memberRepo.findByIdUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.GROUP_NOT_MEMBER));

        if (membership.getRole() == GroupRole.OWNER) {
            disbandGroupInternal(membership.getGroupId());
        } else {
            petRepo.removeGroupFromUserPets(userId, membership.getGroupId());
            memberRepo.delete(membership);
        }
    }

    // ── 강제 탈퇴 (OWNER 전용) ────────────────────────────────────────

    @Transactional
    public void kickMember(Long ownerId, Long targetUserId) {
        BreedingGroupUserRls ownerMembership = getOwnerMembership(ownerId);
        Long groupId = ownerMembership.getGroupId();

        if (ownerId.equals(targetUserId)) {
            throw new BusinessException(ErrorCode.GROUP_CANNOT_KICK_OWNER);
        }

        BreedingGroupUserRls target = memberRepo
                .findById(new io.bitpet.group.domain.BreedingGroupUserRlsId(groupId, targetUserId))
                .orElseThrow(() -> new BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND));

        petRepo.removeGroupFromUserPets(targetUserId, groupId);
        memberRepo.delete(target);
    }

    // ── 내부 헬퍼 ─────────────────────────────────────────────────────

    private void disbandGroupInternal(Long groupId) {
        petRepo.removeGroupFromAllPets(groupId);
        memberRepo.deleteByIdGroupId(groupId);
        groupRepo.findById(groupId).ifPresent(BreedingGroupMst::softDelete);
    }

    private BreedingGroupUserRls getOwnerMembership(Long userId) {
        BreedingGroupUserRls m = memberRepo.findByIdUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.GROUP_NOT_MEMBER));
        if (m.getRole() != GroupRole.OWNER) {
            throw new BusinessException(ErrorCode.GROUP_ACCESS_DENIED);
        }
        return m;
    }

    private GroupResponse buildGroupResponse(BreedingGroupMst group, GroupRole myRole) {
        List<BreedingGroupUserRls> rlsList = memberRepo.findAllByGroupId(group.getId());
        List<GroupMemberResponse> members = rlsList.stream()
                .map(rls -> {
                    var user = userRepo.findById(rls.getUserId()).orElse(null);
                    String name  = user != null ? user.getName()  : "알 수 없음";
                    String email = user != null ? user.getEmail() : "";
                    return GroupMemberResponse.of(rls, name, email);
                })
                .toList();
        return GroupResponse.of(group, myRole, members);
    }

    private String generateUniqueCode() {
        for (int i = 0; i < CODE_RETRY; i++) {
            StringBuilder sb = new StringBuilder(CODE_LEN);
            for (int j = 0; j < CODE_LEN; j++) {
                sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
            }
            String code = sb.toString();
            if (!groupRepo.existsByInviteCode(code)) return code;
        }
        throw new BusinessException(ErrorCode.INTERNAL_ERROR, "초대코드 생성에 실패했습니다");
    }
}
