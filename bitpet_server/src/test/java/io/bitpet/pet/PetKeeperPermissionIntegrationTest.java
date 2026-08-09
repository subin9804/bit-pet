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
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetRelationResponse;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.service.PetService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * OWNER / KEEPER 권한 경계 고정.
 *
 * <p>경계의 기준은 <b>"되돌릴 수 있는가 / 소유권이 움직이는가"</b>이지 중요도가 아니다.
 * 두 역할은 실질적으로 공동 사육자(대개 가족)라 일상 동작을 소유자에게 묶으면 함께 키우는 쪽이
 * 계속 막히고, 반대로 사장-직원처럼 수직 관계일 수도 있어 되돌릴 수 없는 동작은 열 수 없다.
 *
 * <p>이 경계는 <b>조용히 무너지는 종류</b>다. 누군가 `assertKeeper` 를 `assertOwner` 로 바꿔도
 * 소유자 계정으로 하는 수동 테스트는 전부 통과한다. 그래서 양쪽(열려야 하는 것 / 막혀야 하는 것)을
 * 다 고정한다.
 */
class PetKeeperPermissionIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetKeeperRlsRepository keeperRepository;

    // -------------------------------------------------------------------------
    // KEEPER 에게 열려 있어야 하는 것 — 되돌릴 수 있는 동작
    // -------------------------------------------------------------------------

    @Test
    void 공동사육자도_이별_처리하고_되돌릴_수_있다() {
        Long owner  = signup();
        Long keeper = signup();
        Long petId  = createPet(owner, "레오");
        shareWith(petId, keeper);

        // 폐사는 소유권 판단이 아니라 일어난 사실의 기록이고, 그 사실을 먼저 아는 사람이
        // 소유자라는 보장이 없다. 소유자 계정을 기다리면 기록 시점이 어긋난다
        PetResponse marked = petService.markDeceased(keeper, petId, LocalDate.of(2026, 8, 9));
        assertThat(marked.deceasedAt()).isEqualTo(LocalDate.of(2026, 8, 9));

        // 표시할 수 있는 사람이 되돌릴 수도 있어야 한다
        assertThat(petService.revertDeceased(keeper, petId).deceasedAt()).isNull();
    }

    @Test
    void 공동사육자도_가계도_부모를_걸고_뗄_수_있다() {
        Long owner  = signup();
        Long keeper = signup();
        Long child  = createPet(owner, "새끼");
        Long parent = createPet(owner, "아빠");
        shareWith(child, keeper);

        PetRelationResponse rel = petService.addRelation(
                keeper, new PetRelationRequest(parent, child, RelationType.FATHER));
        assertThat(petService.listRelations(keeper, child)).isNotEmpty();

        // 등록을 열었으면 해제도 같은 범위여야 자기가 건 걸 되돌릴 수 있다
        petService.deleteRelation(keeper, rel.id());
        assertThat(petService.listRelations(keeper, child)).isEmpty();
    }

    @Test
    void 가계도_판정축은_자식쪽이지_소유자가_아니다() {
        Long owner       = signup();
        Long childKeeper = signup();
        Long child  = createPet(owner, "새끼");
        Long parent = createPet(signup(), "남의아빠");   // 부모는 완전히 남의 개체
        shareWith(child, childKeeper);

        // 부모 쪽 소유자는 묻지 않는다 — 승인·차단 절차가 없다는 게 정책이다
        PetRelationResponse rel = petService.addRelation(
                childKeeper, new PetRelationRequest(parent, child, RelationType.FATHER));

        // 반대로 부모 쪽 사육자에게는 해제 권한이 없다. 주면 그게 곧 차단 절차가 되어
        // "승인 없음" 원칙이 깨진다
        Long parentOwner = ownerOf(parent);
        assertThatThrownBy(() -> petService.deleteRelation(parentOwner, rel.id()))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_ACCESS_DENIED);
    }

    // -------------------------------------------------------------------------
    // OWNER 에게 남아 있어야 하는 것 — 되돌릴 수 없거나 소유권이 움직이는 동작
    // -------------------------------------------------------------------------

    @Test
    void 공동사육자는_개체를_삭제할_수_없다() {
        Long owner  = signup();
        Long keeper = signup();
        Long petId  = createPet(owner, "레오");
        shareWith(petId, keeper);

        // 삭제는 되돌릴 수 없다 — 이별(폐사)과 갈리는 지점이 정확히 여기다
        assertThatThrownBy(() -> petService.delete(keeper, petId))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_ACCESS_DENIED);

        assertThatCode(() -> petService.delete(owner, petId)).doesNotThrowAnyException();
    }

    @Test
    void 공동사육자는_벌크_삭제에도_끼워넣을_수_없다() {
        Long owner  = signup();
        Long keeper = signup();
        Long mine   = createPet(keeper, "내개체");
        Long shared = createPet(owner, "공유받은개체");
        shareWith(shared, keeper);

        // all-or-nothing 이므로 내 개체까지 함께 실패해야 한다 — 일부만 지워지면 복구 방법이 없다
        assertThatThrownBy(() -> petService.deleteAll(keeper, List.of(mine, shared)))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_ACCESS_DENIED);

        assertThat(petService.get(keeper, mine)).isNotNull();
    }

    // -------------------------------------------------------------------------
    // 사육자가 아예 아닌 사람
    // -------------------------------------------------------------------------

    @Test
    void 사육자가_아니면_이별도_가계도도_막힌다() {
        Long owner    = signup();
        Long stranger = signup();
        Long petId    = createPet(owner, "레오");
        Long parent   = createPet(stranger, "남의아빠");

        assertThatThrownBy(() -> petService.markDeceased(stranger, petId, LocalDate.now()))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_ACCESS_DENIED);

        // 자식이 내 개체가 아니면 부모를 걸 수 없다 (부모 쪽이 내 개체여도 마찬가지)
        assertThatThrownBy(() -> petService.addRelation(
                stranger, new PetRelationRequest(parent, petId, RelationType.FATHER)))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.PET_ACCESS_DENIED);
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "perm" + n + "@example.com", "Passw0rd!23", "permuser" + n)).id();
    }

    private Long createPet(Long userId, String name) {
        PetResponse res = petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null));
        return res.id();
    }

    /** 공유 수락까지 끝난 상태를 만든다 (초대 플로우 자체는 PetSharingService 쪽 관심사) */
    private void shareWith(Long petId, Long keeperUserId) {
        keeperRepository.save(PetKeeperRls.of(petId, keeperUserId, PetKeeperRole.KEEPER));
    }

    private Long ownerOf(Long petId) {
        return keeperRepository.findOwner(petId).orElseThrow().getUserId();
    }
}
