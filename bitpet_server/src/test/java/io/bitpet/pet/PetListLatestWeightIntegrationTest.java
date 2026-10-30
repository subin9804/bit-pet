package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.service.PetService;
import io.bitpet.record.dto.WeightCreateRequest;
import io.bitpet.record.service.RecordService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 개체 목록의 최신 체중 — 개체마다 조회하던 것을 목록 전체 한 번(DISTINCT ON)으로 바꿨다.
 * 바꾼 쿼리가 "개체별 가장 최근 측정값, 지운 기록 제외"를 그대로 지키는지 본다.
 */
class PetListLatestWeightIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private PetService petService;
    @Autowired private RecordService recordService;
    @Autowired private AuthService authService;

    @Test
    void list_shows_each_pets_latest_weight_ignoring_deleted_records() {
        Long user = signup();
        Long a = createPet(user, "가");
        Long b = createPet(user, "나");
        Long none = createPet(user, "다");

        Instant now = Instant.now();
        addWeight(user, a, "100", now.minus(3, ChronoUnit.DAYS));
        addWeight(user, a, "150", now.minus(1, ChronoUnit.DAYS));
        // 가장 최근 기록을 지우면 그 전 값이 최신이 돼야 한다
        Long newest = addWeight(user, a, "999", now);
        recordService.deleteWeight(user, newest);

        addWeight(user, b, "80", now.minus(2, ChronoUnit.DAYS));

        Map<Long, PetResponse> byId = petService.listByOwner(user).stream()
                .collect(Collectors.toMap(PetResponse::id, Function.identity()));

        assertThat(byId.get(a).latestWeightG()).isEqualTo(150.0);
        assertThat(byId.get(b).latestWeightG()).isEqualTo(80.0);
        assertThat(byId.get(none).latestWeightG()).isNull();
        // 상세도 같은 쿼리를 쓴다
        assertThat(petService.get(user, a).latestWeightG()).isEqualTo(150.0);
    }

    // -------------------------------------------------------------------------

    private Long addWeight(Long user, Long petId, String grams, Instant at) {
        return recordService.addWeight(user, petId,
                new WeightCreateRequest(new BigDecimal(grams), at, null, null)).id();
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "plw" + n + "@example.com", "Passw0rd!23", "plwuser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name) {
        return petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                null, null, null, null, null)).id();
    }
}
