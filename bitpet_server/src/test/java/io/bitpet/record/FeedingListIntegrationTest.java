package io.bitpet.record;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.service.PetService;
import io.bitpet.record.dto.FeedingCreateRequest;
import io.bitpet.record.dto.FeedingResponse;
import io.bitpet.record.service.RecordService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 급여 목록 조회 고정.
 *
 * <p>루틴發 기록이 하나도 없는 개체에서 급여 목록 전체가 500 으로 죽었다. 루틴 제목 맵이
 * 비면 {@code Map.of()} 를 돌려줬는데, 불변 빈 맵은 {@code get(null)} 에서 NPE 를 던진다
 * (HashMap 과 다르다). 루틴을 안 쓰고 직접 적기만 하는 개체가 기본값에 가까운 상태라
 * 사실상 대부분의 개체에서 급여 탭과 캘린더가 막혔다.
 *
 * <p>그래서 이 테스트의 핵심은 <b>루틴 기록을 섞지 않는 것</b>이다. 루틴發 기록이 하나라도
 * 끼면 맵이 HashMap 이 되어 NPE 가 사라지므로 버그가 재현되지 않는다.
 */
class FeedingListIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private RecordService recordService;

    @Test
    void 직접_적은_급여만_있어도_목록이_조회된다() {
        Long user = signup();
        Long pet  = createPet(user, "레오");
        recordService.addFeeding(user, pet, feeding("귀뚜라미", Instant.parse("2026-10-11T09:00:00Z")));
        recordService.addFeeding(user, pet, feeding("밀웜",     Instant.parse("2026-10-12T09:00:00Z")));

        assertThat(recordService.listFeedings(user, pet))
                .hasSize(2)
                .extracting(FeedingResponse::routineTitle)
                .containsOnlyNulls();   // 루틴發이 아니므로 제목은 전부 null
    }

    @Test
    void 급여가_하나도_없으면_빈_목록이다() {
        Long user = signup();
        Long pet  = createPet(user, "루나");

        assertThat(recordService.listFeedings(user, pet)).isEmpty();
    }

    /**
     * {@code food_type = ""}(먹이 미입력) 은 <b>루틴 완료 경로에서만</b> 생기는 상태다.
     * REST 로는 만들 수 없다 — 폼에서 종류를 비워 보낸 것은 입력 실수이고, 그걸
     * "아직 안 적음" 으로 받아주면 둘을 구별할 수 없게 된다. 거식은 별도 플래그다.
     */
    @Test
    void REST_로는_먹이_종류를_비워_보낼_수_없다() {
        Long user = signup();
        Long pet  = createPet(user, "모모");

        assertThatThrownBy(() -> recordService.addFeeding(
                user, pet, feeding("", Instant.parse("2026-10-12T09:00:00Z"))))
                .isInstanceOf(BusinessException.class);
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "feedlist" + n + "@example.com", "Passw0rd!23", "feedlistuser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name) {
        PetResponse res = petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null, null, null));
        return res.id();
    }

    private static FeedingCreateRequest feeding(String foodType, Instant fedAt) {
        return new FeedingCreateRequest(foodType, null, null, null, null, fedAt, null, null);
    }
}
