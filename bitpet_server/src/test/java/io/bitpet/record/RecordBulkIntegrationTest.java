package io.bitpet.record;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.service.PetService;
import io.bitpet.record.domain.CleaningType;
import io.bitpet.record.dto.CleaningCreateRequest;
import io.bitpet.record.dto.FeedingCreateRequest;
import io.bitpet.record.dto.RecentRecordResponse;
import io.bitpet.record.dto.RecordBulkRequest.Item;
import io.bitpet.record.dto.WeightCreateRequest;
import io.bitpet.record.service.RecordBulkService;
import io.bitpet.record.service.RecordService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 홈 캘린더 날짜 시트의 일괄 삭제 · 일괄 날짜 변경 고정.
 *
 * <p>날짜를 잘못 고른 채 여러 마리를 적은 경우를 한 번에 되돌리는 기능이다. 지켜야 할 것:
 * 시각은 그대로 두고 날짜만 옮긴다, 남의 기록이 하나라도 끼면 <b>전부</b> 안 바뀐다.
 */
class RecordBulkIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private RecordService recordService;
    @Autowired private RecordBulkService bulkService;

    private static final LocalDate WRONG = LocalDate.of(2026, 10, 18);
    private static final LocalDate RIGHT = LocalDate.of(2026, 10, 17);
    // 10/18 09:30 KST
    private static final Instant AT = Instant.parse("2026-10-18T00:30:00Z");

    @Test
    void 여러_종류_여러_개체의_날짜를_한꺼번에_옮긴다_시각은_유지() {
        Long user = signup();
        Long a = createPet(user, "핑핑");
        Long b = createPet(user, "퐁퐁");
        Long f = recordService.addFeeding(user, a, feeding(AT)).id();
        Long w = recordService.addWeight(user, b, new WeightCreateRequest(
                new BigDecimal("55.5"), AT, null, null)).id();
        Long c = recordService.addCleaning(user, b, new CleaningCreateRequest(
                CleaningType.FULL, AT, null)).id();

        int n = bulkService.move(user, List.of(
                new Item("FEEDING", f), new Item("WEIGHT", w), new Item("cleaning", c)), RIGHT);

        assertThat(n).isEqualTo(3);
        assertThat(recordService.getRecordsByDate(user, WRONG)).isEmpty();
        List<RecentRecordResponse> moved = recordService.getRecordsByDate(user, RIGHT);
        assertThat(moved).hasSize(3);
        assertThat(moved).allSatisfy(r -> {
            var kst = r.createdAt().atZone(SEOUL);
            assertThat(kst.toLocalDate()).isEqualTo(RIGHT);
            assertThat(kst.getHour()).isEqualTo(9);
            assertThat(kst.getMinute()).isEqualTo(30);
        });
    }

    @Test
    void 일괄_삭제() {
        Long user = signup();
        Long a = createPet(user, "루루");
        Long f1 = recordService.addFeeding(user, a, feeding(AT)).id();
        Long f2 = recordService.addFeeding(user, a, feeding(AT)).id();

        bulkService.delete(user, List.of(new Item("FEEDING", f1), new Item("FEEDING", f2)));

        assertThat(recordService.getRecordsByDate(user, WRONG)).isEmpty();
    }

    @Test
    void 남의_기록이_하나라도_끼면_아무것도_바뀌지_않는다() {
        Long me    = signup();
        Long other = signup();
        Long mine   = recordService.addFeeding(me, createPet(me, "내것"), feeding(AT)).id();
        Long theirs = recordService.addFeeding(other, createPet(other, "남의것"), feeding(AT)).id();

        assertThatThrownBy(() -> bulkService.delete(me, List.of(
                new Item("FEEDING", mine), new Item("FEEDING", theirs))))
                .isInstanceOf(BusinessException.class);

        assertThat(recordService.getRecordsByDate(me, WRONG)).hasSize(1);
        assertThat(recordService.getRecordsByDate(other, WRONG)).hasSize(1);
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "bulk" + n + "@example.com", "Passw0rd!23", "bulkuser" + n, null,
                true, true, true, false)).id();
    }

    private Long createPet(Long userId, String name) {
        return petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null, null, null)).id();
    }

    private static FeedingCreateRequest feeding(Instant fedAt) {
        return new FeedingCreateRequest("CRICKET", null, null, null, null, fedAt, null, null);
    }
}
