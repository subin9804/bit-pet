package io.bitpet.record;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.service.PetService;
import io.bitpet.record.domain.CleaningType;
import io.bitpet.record.dto.CleaningCreateRequest;
import io.bitpet.record.dto.FeedingCreateRequest;
import io.bitpet.record.dto.RecentRecordResponse;
import io.bitpet.record.dto.WeightCreateRequest;
import io.bitpet.record.memo.dto.MemoCreateRequest;
import io.bitpet.record.memo.service.MemoService;
import io.bitpet.record.service.RecordService;
import io.bitpet.record.timeline.dto.RecordTimelineItem;
import io.bitpet.record.timeline.service.TimelineService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 홈 캘린더 날짜 시트 — 날짜 경계와 메모 분류 (2026-11-03).
 *
 * <p>개체 상세는 날짜만 골라서 기록을 <b>그날 00:00 KST</b> 로 저장한다. 하루치 조회가 양끝을
 * 포함하던 시절엔 그 기록이 전날 시트에도 떴다.
 */
class RecordsByDateBoundaryIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private RecordService recordService;
    @Autowired private MemoService memoService;
    @Autowired private TimelineService timelineService;

    private static final LocalDate NOV1 = LocalDate.of(2026, 11, 1);
    private static final LocalDate NOV2 = LocalDate.of(2026, 11, 2);
    // 11/2 00:00 KST 정각
    private static final OffsetDateTime MIDNIGHT = OffsetDateTime.of(2026, 11, 2, 0, 0, 0, 0,
            ZoneOffset.ofHours(9));

    @Test
    void 자정_정각_기록은_그날에만_뜨고_전날엔_안_뜬다() {
        Long user = signup();
        Long pet = createPet(user);
        Instant at = MIDNIGHT.toInstant();
        memoService.createMemo(pet, user, new MemoCreateRequest("ㅇㅇ", MIDNIGHT, null, null));
        recordService.addFeeding(user, pet,
                new FeedingCreateRequest("CRICKET", null, null, null, null, at, null, null));
        recordService.addWeight(user, pet,
                new WeightCreateRequest(new BigDecimal("50.0"), at, null, null));
        recordService.addCleaning(user, pet, new CleaningCreateRequest(CleaningType.FULL, at, null));

        assertThat(recordService.getRecordsByDate(user, NOV1)).isEmpty();
        assertThat(recordService.getRecordsByDate(user, NOV2))
                .extracting(RecentRecordResponse::recordType)
                .containsExactlyInAnyOrder("MEMO", "FEEDING", "WEIGHT", "CLEANING");
    }

    @Test
    void 메모_분류가_응답에_실린다() {
        Long user = signup();
        Long pet = createPet(user);
        memoService.createMemo(pet, user,
                new MemoCreateRequest("허물 벗음", MIDNIGHT.plusHours(10), List.of("SHED"), null));
        memoService.createMemo(pet, user,
                new MemoCreateRequest("그냥 메모", MIDNIGHT.plusHours(11), null, null));

        List<RecentRecordResponse> day = recordService.getRecordsByDate(user, NOV2);
        assertThat(day).filteredOn(r -> "허물 벗음".equals(r.memo()))
                .singleElement().satisfies(r -> assertThat(r.tags()).containsExactly("SHED"));
        assertThat(day).filteredOn(r -> "그냥 메모".equals(r.memo()))
                .singleElement().satisfies(r -> assertThat(r.tags()).isEmpty());
    }

    @Test
    void 개체_상세_캘린더_타임라인에도_메모_분류가_실린다() {
        Long user = signup();
        Long pet = createPet(user);
        memoService.createMemo(pet, user,
                new MemoCreateRequest("허물 벗음", MIDNIGHT.plusHours(10), List.of("SHED"), null));
        memoService.createMemo(pet, user,
                new MemoCreateRequest("그냥 메모", MIDNIGHT.plusHours(11), null, null));

        List<RecordTimelineItem> items = timelineService
                .getTimeline(pet, user, NOV2, null, null, null, 50).items();
        assertThat(items).filteredOn(i -> "허물 벗음".equals(i.summary()))
                .singleElement().satisfies(i -> assertThat(i.tags()).containsExactly("SHED"));
        assertThat(items).filteredOn(i -> "그냥 메모".equals(i.summary()))
                .singleElement().satisfies(i -> assertThat(i.tags()).isNullOrEmpty());
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "bydate" + n + "@example.com", "Passw0rd!23", "bydateuser" + n, null,
                true, true, true, false, null)).id();
    }

    private Long createPet(Long userId) {
        return petService.create(userId, new PetCreateRequest(
                "핑핑", null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null, null, null)).id();
    }
}
