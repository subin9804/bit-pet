package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetKeeperRole;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetQuotaResponse;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.pet.service.PetService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 1인당 소유 개체 상한 + 폼 안내용 조회 두 개(이름 사용 가능 여부 / 남은 수).
 *
 * <p>상한은 <b>세는 대상을 한 번 잘못 정하면 조용히 틀리는</b> 종류다 — 지운 개체가 계속
 * 자리를 차지하거나, 공유받은 남의 개체가 내 한도를 깎는 식으로. 그래서 숫자가 아니라
 * <b>무엇을 세는지</b>를 고정한다.
 */
class PetQuotaIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetKeeperService petKeeperService;
    @Autowired private PetKeeperRlsRepository keeperRepository;

    // -------------------------------------------------------------------------
    // 세는 대상
    // -------------------------------------------------------------------------

    @Test
    void 지운_개체는_자리를_비운다() {
        Long me = signup();
        Long petId = createPet(me, "레오");
        assertThat(petKeeperService.countOwned(me)).isEqualTo(1);

        petService.delete(me, petId);

        // 키퍼 행은 개체를 지워도 남을 수 있다 — 직접 세면 지운 개체가 평생 한도를 먹는다
        assertThat(petKeeperService.countOwned(me)).isZero();
    }

    @Test
    void 공유받은_개체는_내_한도를_깎지_않는다() {
        Long owner  = signup();
        Long keeper = signup();
        Long shared = createPet(owner, "레오");
        keeperRepository.save(PetKeeperRls.of(shared, keeper, PetKeeperRole.KEEPER));

        // 남의 개체가 내 한도를 먹으면 같이 키우자는 초대를 거절할 이유가 생긴다
        assertThat(petKeeperService.countOwned(keeper)).isZero();
        assertThat(petKeeperService.countOwned(owner)).isEqualTo(1);
    }

    // -------------------------------------------------------------------------
    // 상한
    // -------------------------------------------------------------------------

    @Test
    void 상한에_닿으면_더_만들_수_없다() {
        Long me = signup();
        for (int i = 0; i < PetKeeperService.MAX_OWNED_PETS; i++) {
            createPet(me, "개체" + i);
        }

        assertThatThrownBy(() -> createPet(me, "한마리더"))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_LIMIT_EXCEEDED);

        // 한 마리를 지우면 그 자리로 다시 들어갈 수 있다 (상한은 누적이 아니라 현재 보유 수다)
        petService.delete(me, petService.listByOwner(me).get(0).id());
        assertThatCode(() -> createPet(me, "한마리더")).doesNotThrowAnyException();
    }

    @Test
    void 남의_개체_수는_내_상한과_무관하다() {
        Long other = signup();
        for (int i = 0; i < 3; i++) createPet(other, "남의개체" + i);

        Long me = signup();
        assertThat(petService.quota(me).owned()).isZero();
        assertThatCode(() -> createPet(me, "레오")).doesNotThrowAnyException();
    }

    // -------------------------------------------------------------------------
    // 폼 안내용 조회
    // -------------------------------------------------------------------------

    @Test
    void 남은_수는_서버가_계산해서_내려준다() {
        Long me = signup();
        createPet(me, "레오");
        createPet(me, "소라");

        PetQuotaResponse quota = petService.quota(me);
        assertThat(quota.owned()).isEqualTo(2);
        assertThat(quota.max()).isEqualTo(PetKeeperService.MAX_OWNED_PETS);
        // 앱이 옛 상수로 직접 빼면 "남았다는데 저장이 안 되는" 화면이 된다
        assertThat(quota.remaining()).isEqualTo(PetKeeperService.MAX_OWNED_PETS - 2);
    }

    @Test
    void 이름_사용_가능_여부는_저장과_같은_기준으로_답한다() {
        Long me    = signup();
        Long petId = createPet(me, "레오");

        assertThat(petService.isNameAvailable(me, "레오", null)).isFalse();
        assertThat(petService.isNameAvailable(me, " 레오 ", null)).isFalse();   // 공백만 다른 것도 같은 이름
        assertThat(petService.isNameAvailable(me, "소라", null)).isTrue();

        // 수정 화면은 자기 이름을 그대로 두고 저장한다 — 제외하지 않으면 늘 '중복'이라고 답한다
        assertThat(petService.isNameAvailable(me, "레오", petId)).isTrue();

        // 빈 이름은 '중복'이 아니라 '미입력'이다 (경고는 필수 입력 쪽에서 띄운다)
        assertThat(petService.isNameAvailable(me, "", null)).isTrue();
        assertThat(petService.isNameAvailable(me, "   ", null)).isTrue();

        // 남이 쓰는 이름은 막지 않는다
        assertThat(petService.isNameAvailable(signup(), "레오", null)).isTrue();
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "petquota" + n + "@example.com", "Passw0rd!23", "petquotauser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name) {
        return petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null)).id();
    }
}
