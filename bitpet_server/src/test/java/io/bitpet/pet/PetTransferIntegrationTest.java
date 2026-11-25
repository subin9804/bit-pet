package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.service.PetService;
import io.bitpet.pet.share.domain.ShareInviteStatus;
import io.bitpet.pet.share.domain.ShareInviteType;
import io.bitpet.pet.share.dto.ShareInvitationResponse;
import io.bitpet.pet.share.dto.ShareInviteRequest;
import io.bitpet.pet.share.repository.PetShareInvitationRepository;
import io.bitpet.pet.share.service.PetSharingService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 분양(TRANSFER)은 깨끗한 인계다 (2026-11-25). 새 소유자만 남고 기존 소유자·기존 KEEPER 는 빠진다.
 * 지켜보고 싶으면 먼저 함께 키우기로 공유했다가 분양한다.
 */
class PetTransferIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetSharingService sharingService;
    @Autowired private PetKeeperRlsRepository keeperRepository;
    @Autowired private PetShareInvitationRepository invitationRepository;

    @Test
    void 분양하면_새_소유자만_남고_기존_소유자와_사육자는_빠진다() {
        Long owner  = signup();
        Long keeper = signup();
        Long buyer  = signup();
        Long petId  = createPet(owner, "레오");
        sharingService.accept(keeper, sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(keeper), ShareInviteType.SHARE)).id());

        sharingService.accept(buyer, sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(buyer), ShareInviteType.TRANSFER)).id());

        assertThat(keeperRepository.findAllByIdPetId(petId))
                .extracting(k -> k.getUserId()).containsExactly(buyer);
        assertThat(keeperRepository.findOwner(petId).orElseThrow().getUserId()).isEqualTo(buyer);
    }

    @Test
    void 함께_키우던_사람에게_분양해도_그_사람만_남는다() {
        Long owner = signup();
        Long buyer = signup();
        Long petId = createPet(owner, "레오");
        sharingService.accept(buyer, sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(buyer), ShareInviteType.SHARE)).id());

        sharingService.accept(buyer, sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(buyer), ShareInviteType.TRANSFER)).id());

        assertThat(keeperRepository.findAllByIdPetId(petId))
                .extracting(k -> k.getUserId()).containsExactly(buyer);
    }

    @Test
    void 분양되면_기존_소유자가_보낸_다른_대기_초대는_닫힌다() {
        Long owner = signup();
        Long other = signup();
        Long buyer = signup();
        Long petId = createPet(owner, "레오");
        ShareInvitationResponse stale = sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(other), ShareInviteType.SHARE));

        sharingService.accept(buyer, sharingService.invite(owner, petId,
                new ShareInviteRequest(codeOf(buyer), ShareInviteType.TRANSFER)).id());

        assertThat(invitationRepository.findById(stale.id()).orElseThrow().getStatus())
                .isEqualTo(ShareInviteStatus.CANCELED);
        assertThat(keeperRepository.existsByIdPetIdAndIdUserId(petId, other)).isFalse();
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "xfer" + n + "@example.com", "Passw0rd!23", "xferuser" + n, null,
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
