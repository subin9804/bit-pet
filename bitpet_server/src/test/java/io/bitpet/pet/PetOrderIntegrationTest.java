package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.pet.service.PetService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 내 개체 목록 순서 — 사람마다 따로(pet_keeper_rls.sort_order).
 *
 * <p>고정하는 것: 새 개체는 맨 위 / 저장한 순서 그대로 / 공유받은 쪽 순서가 소유자에게 번지지 않음 /
 * 이별 개체는 순서와 무관하게 맨 뒤 / 남의 id·빠진 id 는 저장을 깨지 않음.
 */
class PetOrderIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetKeeperService petKeeper;

    @Test
    void 새_개체는_맨_위에_온다() {
        Long user = signup();
        Long a = createPet(user, "가");
        Long b = createPet(user, "나");
        Long c = createPet(user, "다");

        assertThat(ids(user)).containsExactly(c, b, a);
    }

    @Test
    void 저장한_순서대로_보이고_이별_개체는_맨_뒤() {
        Long user = signup();
        Long a = createPet(user, "가");
        Long b = createPet(user, "나");
        Long c = createPet(user, "다");

        petService.reorder(user, List.of(a, c, b));
        assertThat(ids(user)).containsExactly(a, c, b);

        // 맨 앞 개체가 이별하면 순서값과 무관하게 맨 뒤로
        petService.markDeceased(user, a, LocalDate.of(2026, 10, 1));
        assertThat(ids(user)).containsExactly(c, b, a);
    }

    @Test
    void 공유받은_쪽의_순서는_소유자에게_번지지_않는다() {
        Long owner  = signup();
        Long keeper = signup();
        Long a = createPet(owner, "가");
        Long b = createPet(owner, "나");
        petKeeper.registerKeeper(a, keeper);
        petKeeper.registerKeeper(b, keeper);

        petService.reorder(keeper, List.of(a, b));
        petService.reorder(owner, List.of(b, a));

        assertThat(ids(keeper)).containsExactly(a, b);
        assertThat(ids(owner)).containsExactly(b, a);
    }

    @Test
    void 남의_id는_무시하고_빠진_내_개체는_뒤로_붙는다() {
        Long user  = signup();
        Long other = signup();
        Long a = createPet(user, "가");
        Long b = createPet(user, "나");
        Long c = createPet(user, "다");
        Long foreign = createPet(other, "남의");

        // c, b, a 순인 상태에서 a 와 남의 개체만 보낸다
        petService.reorder(user, List.of(foreign, a));

        assertThat(ids(user)).containsExactly(a, c, b);
        assertThat(ids(other)).containsExactly(foreign);
    }

    private List<Long> ids(Long userId) {
        return petService.listByOwner(userId).stream().map(PetResponse::id).toList();
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "order" + n + "@example.com", "Passw0rd!23", "orderuser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name) {
        return petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null, null, null)).id();
    }
}
