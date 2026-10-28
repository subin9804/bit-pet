package io.bitpet.record;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.record.dto.FeedingUpdateRequest;
import io.bitpet.routine.domain.RoutineLogStatus;
import io.bitpet.routine.domain.RoutineType;
import io.bitpet.routine.dto.RoutineCompleteIndividualRequest;
import io.bitpet.routine.dto.RoutineCreateRequest;
import io.bitpet.routine.service.RoutineService;
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
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

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
    @Autowired private RoutineService routineService;
    @Autowired private JdbcTemplate jdbc;

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
     * 먹이 종류 없이 보낸 급여는 {@code food_type = ""} — "급여는 했고 뭘 줬는지 안 적음" 이다
     * (2026-10-28). FAB 에서 급여 사실만 빠르게 남길 수 있어야 한다. 거식(NULL)과는 다른 상태다.
     * 예전엔 400 이었다.
     */
    @Test
    void 먹이_종류_없이_보내면_빈_급여_기록이_생긴다() {
        Long user = signup();
        Long pet  = createPet(user, "모모");

        FeedingResponse saved = recordService.addFeeding(
                user, pet, feeding(null, Instant.parse("2026-10-12T09:00:00Z")));

        assertThat(saved.foodType()).isEmpty();
        assertThat(saved.refused()).isFalse();
    }

    /**
     * 먹이 없이 남긴 급여의 메모·날짜를 고치면 앱이 {@code refused=false, foodType=""} 를 보낸다.
     * 예전엔 서버가 400 으로 막아 수정이 통째로 실패했다.
     */
    @Test
    void 빈_급여_기록의_메모를_고칠_수_있다() {
        Long user = signup();
        Long pet  = createPet(user, "보리");
        FeedingResponse saved = recordService.addFeeding(
                user, pet, feeding("", Instant.parse("2026-10-12T09:00:00Z")));

        FeedingResponse updated = recordService.updateFeeding(user, saved.id(), new FeedingUpdateRequest(
                "", null, null, null, null, null, "잘 먹음", false));

        assertThat(updated.foodType()).isEmpty();
        assertThat(updated.memo()).isEqualTo("잘 먹음");
    }

    /**
     * 급여 루틴을 먹이 없이 메모만 적고 완료하면 메모는 <b>급여 기록에</b> 붙어야 한다.
     * 별도 메모 기록({@code memo_dtl})으로 새면 같은 급여가 두 줄로 갈라진다 (2026-10-28 사용자 제보).
     */
    @Test
    void 급여_루틴을_메모만_적고_완료하면_메모가_급여_기록에_붙는다() {
        Long user = signup();
        Long pet  = createPet(user, "콩이");
        Long routine = routineService.createRoutine(user, new RoutineCreateRequest(
                RoutineType.FEEDING, "급여", 3, null, false, List.of(pet), null, null,
                null, null, null)).id();

        routineService.completeIndividual(user, routine, new RoutineCompleteIndividualRequest(
                pet, RoutineLogStatus.COMPLETED, Instant.parse("2026-10-12T09:00:00Z"),
                null, null, null, "반만 먹음"));

        assertThat(recordService.listFeedings(user, pet))
                .singleElement()
                .satisfies(f -> {
                    assertThat(f.foodType()).isEmpty();
                    assertThat(f.memo()).isEqualTo("반만 먹음");
                });
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM memo_dtl WHERE pet_id = ? AND deleted_at IS NULL",
                Integer.class, pet)).isZero();
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
