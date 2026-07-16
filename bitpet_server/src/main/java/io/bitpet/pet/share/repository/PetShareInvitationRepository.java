package io.bitpet.pet.share.repository;

import io.bitpet.pet.share.domain.PetShareInvitation;
import io.bitpet.pet.share.domain.ShareInviteStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PetShareInvitationRepository
        extends JpaRepository<PetShareInvitation, Long> {

    /** 받은 초대함 (상태별) */
    List<PetShareInvitation> findAllByInviteeUserIdAndStatusOrderByCreatedAtDesc(
            Long inviteeUserId, ShareInviteStatus status);

    /** 개체에 대해 보낸 초대 (상태별) */
    List<PetShareInvitation> findAllByPetIdAndStatusOrderByCreatedAtDesc(
            Long petId, ShareInviteStatus status);

    /** 동일 개체·대상 PENDING 중복 확인 */
    Optional<PetShareInvitation> findByPetIdAndInviteeUserIdAndStatus(
            Long petId, Long inviteeUserId, ShareInviteStatus status);
}
