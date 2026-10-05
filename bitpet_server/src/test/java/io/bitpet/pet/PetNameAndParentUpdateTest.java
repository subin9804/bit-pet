package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetKeeperRole;
import io.bitpet.pet.domain.RelationType;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.service.PetService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 개체 이름 중복 금지 + 수정으로 부모 갈아끼우기.
 *
 * <p>둘 다 <b>조용히 무너지는 종류</b>라 양쪽을 고정한다. 이름 검사는 범위(사람 단위 vs 전역)를
 * 한 글자 바꾸면 흔한 이름이 선착순으로 소진되고, 부모 수정은 {@code editParents} 플래그를
 * 빼는 순간 부모를 모르는 저장 경로가 가계도를 지워버린다 — 둘 다 수동 테스트로는 안 드러난다.
 */
class PetNameAndParentUpdateTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetKeeperRlsRepository keeperRepository;

    // -------------------------------------------------------------------------
    // 이름 중복
    // -------------------------------------------------------------------------

    @Test
    void 같은_사람이_같은_이름을_두_번_쓸_수_없다() {
        Long me = signup();
        createPet(me, "레오");

        assertThatThrownBy(() -> createPet(me, "레오"))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_NAME_DUPLICATE);

        // 공백·대소문자만 다른 것도 같은 이름이다 — 목록에서 구분이 안 된다
        assertThatThrownBy(() -> createPet(me, "  레오 "))
                .isInstanceOf(BusinessException.class);
        // 대소문자는 영문 이름에서만 의미가 있다 ("LEO" 는 "레오"의 변형이 아니다)
        createPet(me, "Leo");
        assertThatThrownBy(() -> createPet(me, "leo"))
                .isInstanceOf(BusinessException.class);

        assertThatCode(() -> createPet(me, "소라")).doesNotThrowAnyException();   // 다른 이름은 통과
    }

    @Test
    void 남이_쓰는_이름은_막지_않는다() {
        Long other = signup();
        createPet(other, "레오");

        // 범위가 전역이면 흔한 이름이 선착순으로 소진된다
        assertThatCode(() -> createPet(signup(), "레오")).doesNotThrowAnyException();
    }

    @Test
    void 공유받은_개체와도_이름이_겹치면_막는다() {
        Long owner  = signup();
        Long keeper = signup();
        Long shared = createPet(owner, "레오");
        keeperRepository.save(PetKeeperRls.of(shared, keeper, PetKeeperRole.KEEPER));

        // 판정 범위는 pet_keeper_rls 기준이지 pet_mst.user_id 가 아니다 —
        // 공유받은 개체도 내 목록에 함께 떠서 이름이 겹치면 구분이 안 되는 건 똑같다
        assertThatThrownBy(() -> createPet(keeper, "레오"))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_NAME_DUPLICATE);
    }

    @Test
    void 수정에서_자기_이름을_그대로_저장하는_건_중복이_아니다() {
        Long me    = signup();
        Long petId = createPet(me, "레오");

        // 자기 자신을 제외하지 않으면 이름을 안 건드린 저장이 전부 409 가 된다
        assertThatCode(() -> petService.update(me, petId, update("레오", null, null, null)))
                .doesNotThrowAnyException();

        Long other = createPet(me, "소라");
        assertThatThrownBy(() -> petService.update(me, other, update("레오", null, null, null)))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_NAME_DUPLICATE);
    }

    // -------------------------------------------------------------------------
    // 수정으로 부모 갈아끼우기
    // -------------------------------------------------------------------------

    @Test
    void 수정에서_부모를_걸고_바꾸고_비울_수_있다() {
        Long me     = signup();
        Long child  = createPet(me, "새끼");
        Long dad1   = createPet(me, "아빠1");
        Long dad2   = createPet(me, "아빠2");

        petService.update(me, child, update(null, true, dad1, null));
        assertThat(fatherOf(me, child)).isEqualTo(dad1);

        // 바꾸기 — 지웠다 다시 거는 경로라 addRelation 의 중복 검사에 자기가 걸리면 터진다
        petService.update(me, child, update(null, true, dad2, null));
        assertThat(fatherOf(me, child)).isEqualTo(dad2);

        // 비우기 — editParents 가 켜져 있으면 null 은 "해제"다
        petService.update(me, child, update(null, true, null, null));
        assertThat(fatherOf(me, child)).isNull();
    }

    @Test
    void editParents_가_없으면_부모를_건드리지_않는다() {
        Long me    = signup();
        Long child = createPet(me, "새끼");
        Long dad   = createPet(me, "아빠");
        petService.update(me, child, update(null, true, dad, null));

        // 부모 필드를 모르는 경로(오프라인 sync push, 구버전 앱)가 저장해도 가계도는 그대로여야 한다
        petService.update(me, child, update("새끼2", null, null, null));
        assertThat(fatherOf(me, child)).isEqualTo(dad);
    }

    @Test
    void 같은_부모를_다시_보내면_관계가_유지된다() {
        Long me    = signup();
        Long child = createPet(me, "새끼");
        Long dad   = createPet(me, "아빠");

        petService.update(me, child, update(null, true, dad, null));
        Long relationId = petService.listRelations(me, child).get(0).id();

        // 변경이 없는 저장마다 관계 id 가 바뀌면 가계도 참조가 흔들린다
        petService.update(me, child, update(null, true, dad, null));
        assertThat(petService.listRelations(me, child)).hasSize(1);
        assertThat(petService.listRelations(me, child).get(0).id()).isEqualTo(relationId);
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "petname" + n + "@example.com", "Passw0rd!23", "petnameuser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name) {
        PetResponse res = petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null));
        return res.id();
    }

    private PetUpdateRequest update(String name, Boolean editParents, Long father, Long mother) {
        return new PetUpdateRequest(
                name,
                null, null, null,          // speciesId, morphIds, morphId
                null, null, null,          // gender, colorCode, description
                null, null, null, null,    // breedingDate, hatchingDate, precision, approximate
                null, null,                // adoptionDate, privateYn
                editParents, father, mother);
    }

    /** 부(♂) 관계의 부모 개체 id. 없으면 null */
    private Long fatherOf(Long userId, Long childPetId) {
        return petService.listRelations(userId, childPetId).stream()
                .filter(r -> r.relationType() == RelationType.FATHER)
                .map(r -> r.parentPetId())
                .findFirst()
                .orElse(null);
    }
}
