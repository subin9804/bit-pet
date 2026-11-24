package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.service.PetService;
import io.bitpet.pet.share.domain.ShareInviteStatus;
import io.bitpet.pet.share.domain.ShareInviteType;
import io.bitpet.pet.share.dto.BulkShareInviteRequest;
import io.bitpet.pet.share.dto.ShareInvitationResponse;
import io.bitpet.pet.share.dto.ShareInviteRequest;
import io.bitpet.pet.share.repository.PetShareInvitationRepository;
import io.bitpet.pet.share.service.PetSharingService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 이별한 개체는 <b>새로</b> 공유·분양할 수 없다. 이미 함께 키우던 사람은 그대로 둔다 —
 * 같이 키운 기록·사진을 계속 볼 수 있어야 한다. 이별 취소하면 다시 된다.
 */
class PetDeceasedSharingIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetSharingService sharingService;
    @Autowired private PetKeeperRlsRepository keeperRepository;
    @Autowired private PetShareInvitationRepository invitationRepository;

    @Test
    void 이별한_개체는_공유도_분양도_초대할_수_없다() {
        Long owner = signup();
        String code = codeOf(signup());
        Long petId = createPet(owner, "레오");
        petService.markDeceased(owner, petId, LocalDate.of(2026, 11, 1));

        for (ShareInviteType type : ShareInviteType.values()) {
            assertThatThrownBy(() -> sharingService.invite(owner, petId, new ShareInviteRequest(code, type)))
                    .isInstanceOf(BusinessException.class)
                    .extracting(e -> ((BusinessException) e).getErrorCode())
                    .isEqualTo(ErrorCode.SHARE_PET_DECEASED);
        }
    }

    @Test
    void 여러마리_초대에서는_이별한_개체만_빠진다() {
        Long owner = signup();
        String code = codeOf(signup());
        Long alive = createPet(owner, "레오");
        Long gone  = createPet(owner, "루나");
        petService.markDeceased(owner, gone, null);

        var batch = sharingService.inviteBulk(owner,
                new BulkShareInviteRequest(code, ShareInviteType.SHARE, List.of(alive, gone)));
        assertThat(invitationRepository.findAll().stream()
                .filter(i -> i.getBatchId().equals(batch.batchId()))
                .map(i -> i.getPetId())).containsExactly(alive);

        // 이별한 개체만 고르면 초대할 게 없다
        assertThatThrownBy(() -> sharingService.inviteBulk(owner,
                new BulkShareInviteRequest(code, ShareInviteType.TRANSFER, List.of(gone))))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.SHARE_BULK_NO_VALID_PET);
    }

    @Test
    void 초대_뒤에_이별하면_수락해도_붙지_않고_초대가_닫힌다() {
        Long owner   = signup();
        Long invitee = signup();
        Long petId   = createPet(owner, "레오");
        ShareInvitationResponse inv = sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(invitee), ShareInviteType.TRANSFER));
        petService.markDeceased(owner, petId, null);

        sharingService.accept(invitee, inv.id());

        assertThat(invitationRepository.findById(inv.id()).orElseThrow().getStatus())
                .isEqualTo(ShareInviteStatus.CANCELED);
        assertThat(keeperRepository.existsByIdPetIdAndIdUserId(petId, invitee)).isFalse();
        assertThat(keeperRepository.findOwner(petId).orElseThrow().getUserId()).isEqualTo(owner);
    }

    @Test
    void 자녀에게_전체_공유할_때_이별한_개체는_빠지고_이미_공유된_건_남는다() {
        Long owner = signup();
        Long child = signup();
        Long alive = createPet(owner, "레오");
        Long gone  = createPet(owner, "루나");
        sharingService.shareAllOwnedTo(owner, child);   // 둘 다 공유된 상태에서

        Long later = createPet(owner, "모카");
        petService.markDeceased(owner, later, null);
        petService.markDeceased(owner, gone, null);

        assertThat(sharingService.shareAllOwnedTo(owner, child)).isZero();
        assertThat(keeperRepository.existsByIdPetIdAndIdUserId(later, child)).isFalse();
        // 이별 전에 공유된 개체는 그대로
        assertThat(keeperRepository.existsByIdPetIdAndIdUserId(gone, child)).isTrue();
        assertThat(keeperRepository.existsByIdPetIdAndIdUserId(alive, child)).isTrue();
    }

    @Test
    void 이별_취소하면_다시_공유할_수_있다() {
        Long owner = signup();
        String code = codeOf(signup());
        Long petId = createPet(owner, "레오");
        petService.markDeceased(owner, petId, null);
        petService.revertDeceased(owner, petId);

        assertThat(sharingService.invite(owner, petId,
                new ShareInviteRequest(code, ShareInviteType.SHARE)).status())
                .isEqualTo(ShareInviteStatus.PENDING);
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "rip" + n + "@example.com", "Passw0rd!23", "ripuser" + n, null,
                true, true, true, null, false, null)).id();
    }

    private String codeOf(Long userId) {
        return sharingService.myShareCode(userId).shareCode();
    }

    private Long createPet(Long userId, String name) {
        return petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null, null, null)).id();
    }
}
