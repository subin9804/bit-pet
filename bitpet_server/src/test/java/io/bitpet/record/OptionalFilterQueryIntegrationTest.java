package io.bitpet.record;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.service.PetService;
import io.bitpet.record.laying.dto.LayingCreateRequest;
import io.bitpet.record.laying.dto.LayingResponse;
import io.bitpet.record.laying.service.LayingService;
import io.bitpet.record.mating.dto.MatingCreateRequest;
import io.bitpet.record.mating.dto.MatingResponse;
import io.bitpet.record.mating.service.MatingService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 선택 필터(null 가능 파라미터) 목록 조회 고정.
 *
 * <p>예전엔 {@code (:from IS NULL OR l.laidAt >= :from)} JPQL 이라, 필터 없이 부르면 PostgreSQL 이
 * {@code could not determine data type of parameter $4} 로 500 을 냈다. 앱은 산란 목록을 필터 없이
 * 부르므로 <b>전부 null 인 호출</b>이 가장 중요한 경우다. H2 로는 재현되지 않아 실 PostgreSQL 에서 본다.
 */
class OptionalFilterQueryIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final ZoneOffset KST = ZoneOffset.ofHours(9);

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private LayingService layingService;
    @Autowired private MatingService matingService;

    @Test
    void 산란_목록은_필터가_전부_null_이어도_조회된다() {
        Long user   = signup();
        Long female = createPet(user, "암컷", PetGender.FEMALE);
        layingService.createLaying(female, user, laying(null, OffsetDateTime.of(2026, 5, 1, 10, 0, 0, 0, KST)));
        layingService.createLaying(female, user, laying(null, OffsetDateTime.of(2026, 6, 1, 10, 0, 0, 0, KST)));

        assertThat(layingService.getLayings(female, user, null, null, null))
                .extracting(LayingResponse::laidAt)
                .isSortedAccordingTo((a, b) -> b.compareTo(a))   // 최신순
                .hasSize(2);
    }

    @Test
    void 산란_기간_필터는_to_날짜의_밤늦은_기록까지_포함한다() {
        Long user   = signup();
        Long female = createPet(user, "암컷", PetGender.FEMALE);
        layingService.createLaying(female, user, laying(null, OffsetDateTime.of(2026, 4, 30, 23, 0, 0, 0, KST)));
        layingService.createLaying(female, user, laying(null, OffsetDateTime.of(2026, 5, 31, 23, 59, 0, 0, KST)));
        layingService.createLaying(female, user, laying(null, OffsetDateTime.of(2026, 6, 1, 0, 0, 0, 0, KST)));

        // 5/1 ~ 5/31 (서울 기준) — 경계 양쪽 바깥은 빠지고 5/31 23:59 는 들어와야 한다
        assertThat(layingService.getLayings(female, user, null,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31))).hasSize(1);

        // 한쪽만 준 경우
        assertThat(layingService.getLayings(female, user, null, LocalDate.of(2026, 5, 1), null)).hasSize(2);
        assertThat(layingService.getLayings(female, user, null, null, LocalDate.of(2026, 5, 31))).hasSize(2);
    }

    @Test
    void 산란_메이팅_필터() {
        Long user   = signup();
        Long male   = createPet(user, "수컷", PetGender.MALE);
        Long female = createPet(user, "암컷", PetGender.FEMALE);
        MatingResponse mating = matingService.createMating(female, user, new MatingCreateRequest(
                male, female, null, OffsetDateTime.of(2026, 4, 1, 10, 0, 0, 0, KST), null, true, null, null));

        layingService.createLaying(female, user, laying(mating.matingId(), OffsetDateTime.of(2026, 5, 1, 10, 0, 0, 0, KST)));
        layingService.createLaying(female, user, laying(null, OffsetDateTime.of(2026, 5, 2, 10, 0, 0, 0, KST)));

        assertThat(layingService.getLayings(female, user, mating.matingId(), null, null))
                .extracting(LayingResponse::matingId)
                .containsExactly(mating.matingId());
    }

    @Test
    void 메이팅_목록은_필터가_null_이어도_되고_암수_어느쪽에서도_보인다() {
        Long user   = signup();
        Long male   = createPet(user, "수컷", PetGender.MALE);
        Long female = createPet(user, "암컷", PetGender.FEMALE);
        matingService.createMating(female, user, new MatingCreateRequest(
                male, female, null, OffsetDateTime.of(2026, 4, 1, 10, 0, 0, 0, KST), null, true, null, null));
        matingService.createMating(female, user, new MatingCreateRequest(
                male, female, null, OffsetDateTime.of(2026, 4, 5, 10, 0, 0, 0, KST), null, false, null, null));

        assertThat(matingService.getMatings(male, user, null, null)).hasSize(2);
        assertThat(matingService.getMatings(female, user, null, null)).hasSize(2);
        assertThat(matingService.getMatings(female, user, null, true)).hasSize(1);
    }

    @Test
    void 개체_검색은_필터가_null_이어도_되고_이름은_부분일치다() {
        Long user = signup();
        createPet(user, "Leo", PetGender.MALE);
        createPet(user, "레오나", PetGender.FEMALE);
        createPet(signup(), "Leo", PetGender.MALE);   // 남의 개체는 섞이면 안 된다

        assertThat(petService.search(user, null, null, null)).hasSize(2);
        assertThat(petService.search(user, null, PetGender.FEMALE, null))
                .extracting(PetResponse::name).containsExactly("레오나");
        assertThat(petService.search(user, null, null, "le"))
                .extracting(PetResponse::name).containsExactly("Leo");
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "filter" + n + "@example.com", "Passw0rd!23", "filteruser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name, PetGender gender) {
        PetResponse res = petService.create(userId, new PetCreateRequest(
                name, null, null, gender, null, null, null, null, null, null, null,
                120.0, null, null));
        return res.id();
    }

    private static LayingCreateRequest laying(Long matingId, OffsetDateTime laidAt) {
        return new LayingCreateRequest(matingId, laidAt, 2, null, null, null, null);
    }
}
