package io.bitpet.nfc;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.nfc.domain.NfcTagBindHst;
import io.bitpet.nfc.domain.TagBindAction;
import io.bitpet.nfc.domain.TagStatus;
import io.bitpet.nfc.dto.MyTagResponse;
import io.bitpet.nfc.dto.NfcScanResponse;
import io.bitpet.nfc.service.NfcTagService;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetKeeperRole;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.service.PetService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * NFC 스캔·바인딩 검증.
 *
 * <p>확인하려는 건 두 가지다.
 * <ul>
 *   <li><b>필드 축소를 서버가 하는가</b> — 남의 개체를 스캔했을 때 소유자 정보가
 *       응답에 담기지 않아야 한다. "앱이 안 그리면 된다"로는 지킬 수 없는 약속이다</li>
 *   <li><b>권한 판정 근거가 pet_keeper_rls 인가</b> — 사육자(OWNER/KEEPER)는 붙일 수 있고
 *       사육자가 아니면 못 붙인다. {@code pet_mst.user_id} 로는 이 구분이 안 나온다</li>
 * </ul>
 */
class NfcScanBindIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private NfcTagService nfcTagService;
    @Autowired private PetKeeperRlsRepository keeperRepository;

    @Test
    void 내_개체에_붙은_태그는_카드까지_내려온다() {
        Long owner = signup();
        Long petId = createPet(owner, "레오", PetGender.MALE);
        String tagCd = issueTag();

        nfcTagService.bind(owner, tagCd, petId, false);
        NfcScanResponse res = nfcTagService.scan(owner, tagCd);

        assertThat(res.status()).isEqualTo(TagStatus.LINKED);
        assertThat(res.pet()).isNotNull();
        assertThat(res.pet().petId()).isEqualTo(petId);
        assertThat(res.pet().name()).isEqualTo("레오");
        assertThat(res.pet().isKeeper()).isTrue();
        assertThat(res.pet().owner()).isNotNull();
    }

    @Test
    void 남의_개체를_스캔하면_소유자_정보가_응답에서_빠진다() {
        Long owner     = signup();
        Long stranger  = signup();
        Long petId     = createPet(owner, "남의레오", PetGender.MALE);
        String tagCd   = issueTag();
        nfcTagService.bind(owner, tagCd, petId, false);

        NfcScanResponse res = nfcTagService.scan(stranger, tagCd);

        assertThat(res.status()).isEqualTo(TagStatus.OWNED_BY_OTHER);
        // 개체가 실재한다는 것과 혈통 식별 정보까지는 보여준다
        assertThat(res.pet()).isNotNull();
        assertThat(res.pet().name()).isEqualTo("남의레오");
        assertThat(res.pet().isKeeper()).isFalse();
        // 소유자는 서버가 응답에서 빼 버린다 — 클라이언트 숨김에 맡기지 않는다
        assertThat(res.pet().owner()).isNull();
    }

    @Test
    void 공동사육자도_이름표를_붙일_수_있다() {
        Long owner  = signup();
        Long keeper = signup();
        Long petId  = createPet(owner, "같이키우는개체", PetGender.MALE);
        keeperRepository.save(PetKeeperRls.of(petId, keeper, PetKeeperRole.KEEPER));
        String tagCd = issueTag();

        // 이름표는 개체 이름이 새겨진 채로 팔린다 — 어느 개체용인지가 실물에 이미 박혀 있어서
        // 붙이는 데 소유권 판단이 필요 없다. 같이 키우는 사람이 샀는데 못 붙이면 곤란하다
        nfcTagService.bind(keeper, tagCd, petId, false);
        assertThat(nfcTagService.scan(keeper, tagCd).status()).isEqualTo(TagStatus.LINKED);

        // 공동사육자가 붙였어도 소유자가 떼어낼 수 있어야 한다 (태그를 붙인 본인만 보면 막힌다)
        nfcTagService.unlink(owner, tagCd);
        assertThat(nfcTagService.scan(owner, tagCd).status()).isEqualTo(TagStatus.UNLINKED);
    }

    @Test
    void 사육자가_아니면_이름표를_붙일_수_없다() {
        Long owner    = signup();
        Long stranger = signup();
        Long petId    = createPet(owner, "남의개체", PetGender.MALE);
        String tagCd  = issueTag();

        assertThatThrownBy(() -> nfcTagService.bind(stranger, tagCd, petId, false))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_ACCESS_DENIED);
    }

    @Test
    void 어드민은_출고_전에_붙여두고_태그는_고객_것이_된다() {
        Long owner = signup();
        Long admin = signup();
        Long petId = createPet(owner, "각인된레오", PetGender.MALE);
        String tagCd = issueTag();

        nfcTagService.bindByAdmin(admin, tagCd, petId);

        // 고객은 받아서 찍기만 하면 이미 연결돼 있다
        assertThat(nfcTagService.scan(owner, tagCd).status()).isEqualTo(TagStatus.LINKED);
        // 태그 소유자는 어드민이 아니라 고객이다 — 어드민 목록에 쌓이면 안 된다
        assertThat(nfcTagService.listMyTags(owner)).extracting(MyTagResponse::tagCd).contains(tagCd);
        assertThat(nfcTagService.listMyTags(admin)).isEmpty();
        // 다만 붙인 사람은 이력에 어드민으로 남는다 (문의 대응)
        assertThat(nfcTagService.bindHistory(owner, tagCd))
                .singleElement()
                .satisfies(h -> {
                    assertThat(h.getAction()).isEqualTo(TagBindAction.BIND);
                    assertThat(h.getActorId()).isEqualTo(admin);
                });
    }

    @Test
    void 내_다른_개체에_붙은_태그는_확인_없이는_옮겨지지_않는다() {
        Long owner = signup();
        Long first  = createPet(owner, "첫째", PetGender.MALE);
        Long second = createPet(owner, "둘째", PetGender.FEMALE);
        String tagCd = issueTag();
        nfcTagService.bind(owner, tagCd, first, false);

        assertThatThrownBy(() -> nfcTagService.bind(owner, tagCd, second, false))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.TAG_REBIND_CONFIRM_REQUIRED);

        // 확인을 거치면 옮겨지고, 이력에 어디서 떼어냈는지가 남는다
        nfcTagService.bind(owner, tagCd, second, true);
        assertThat(nfcTagService.scan(owner, tagCd).pet().petId()).isEqualTo(second);

        List<NfcTagBindHst> history = nfcTagService.bindHistory(owner, tagCd);
        assertThat(history).hasSize(2);
        assertThat(history.get(0).getAction()).isEqualTo(TagBindAction.REBIND);
        assertThat(history.get(0).getPetId()).isEqualTo(second);
        assertThat(history.get(0).getPrevPetId()).isEqualTo(first);
        assertThat(history.get(1).getAction()).isEqualTo(TagBindAction.BIND);
    }

    @Test
    void 남의_태그는_확인해도_가져올_수_없다() {
        Long owner    = signup();
        Long stranger = signup();
        String tagCd  = issueTag();
        nfcTagService.bind(owner, tagCd, createPet(owner, "레오", PetGender.MALE), false);

        Long myPet = createPet(stranger, "내레오", PetGender.MALE);
        assertThatThrownBy(() -> nfcTagService.bind(stranger, tagCd, myPet, true))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.TAG_ALREADY_LINKED);
    }

    @Test
    void 소문자로_들어온_태그도_같은_태그다() {
        Long owner   = signup();
        Long petId   = createPet(owner, "레오", PetGender.MALE);
        String tagCd = issueTag();

        nfcTagService.bind(owner, tagCd.toLowerCase(), petId, false);

        assertThat(nfcTagService.scan(owner, tagCd.toLowerCase()).status())
                .isEqualTo(TagStatus.LINKED);
        assertThat(nfcTagService.scan(owner, tagCd).pet().petId()).isEqualTo(petId);
    }

    @Test
    void 차단된_태그는_붙일_수_없고_스캔은_이유를_알려준다() {
        Long owner   = signup();
        Long petId   = createPet(owner, "레오", PetGender.MALE);
        String tagCd = issueTag();
        nfcTagService.revoke(List.of(tagCd));

        assertThat(nfcTagService.scan(owner, tagCd).status()).isEqualTo(TagStatus.REVOKED);
        assertThatThrownBy(() -> nfcTagService.bind(owner, tagCd, petId, true))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.TAG_REVOKED);
    }

    // -------------------------------------------------------------------------

    private String issueTag() {
        return nfcTagService.issueStock(1, null, "TEST").get(0);
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "nfc" + n + "@example.com", "Passw0rd!23", "nfcuser" + n)).id();
    }

    private Long createPet(Long userId, String name, PetGender gender) {
        PetResponse res = petService.create(userId, new PetCreateRequest(
                name, null, null, gender, null, null, null, null, null, null, null,
                120.0, null, null));
        return res.id();
    }
}
