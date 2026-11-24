package io.bitpet.auth;

import io.bitpet.auth.dto.ChildCreateRequest;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.auth.service.GuardianService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.pet.service.PetService;
import io.bitpet.record.calendar.service.CalendarService;
import io.bitpet.record.service.RecordService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** 보호자 '내 개체 전체 공유' (2026-11-18) — 여러 번 눌러도 새로 생긴 개체만 붙는다 */
class GuardianShareAllPetsIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private GuardianService guardianService;
    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetKeeperService petKeeper;
    @Autowired private CalendarService calendarService;
    @Autowired private RecordService recordService;

    @Test
    void share_all_is_idempotent_and_picks_up_new_pets() {
        Long guardian = signup();
        Long child = createChild(guardian);
        Long a = createPet(guardian, "루나");
        Long b = createPet(guardian, "레오");

        assertThat(guardianService.shareAllPetsToChild(guardian, child)).isEqualTo(2);
        assertThat(petKeeper.isKeeper(child, a)).isTrue();
        assertThat(petKeeper.isKeeper(child, b)).isTrue();
        // 소유권은 그대로
        assertThat(petKeeper.isOwner(guardian, a)).isTrue();
        assertThat(petKeeper.isOwner(child, a)).isFalse();
        // 받는 쪽 목록은 보호자 순서 그대로
        assertThat(petKeeper.keptPetIdsOrdered(child)).isEqualTo(petKeeper.keptPetIdsOrdered(guardian));

        // 다시 눌러도 아무 일 없음
        assertThat(guardianService.shareAllPetsToChild(guardian, child)).isZero();

        // 새 개체만 붙는다
        Long c = createPet(guardian, "모모");
        assertThat(guardianService.shareAllPetsToChild(guardian, child)).isEqualTo(1);
        assertThat(petKeeper.isKeeper(child, c)).isTrue();

        // 삭제한 개체는 공유 대상이 아니다
        Long d = createPet(guardian, "지운개체");
        petService.delete(guardian, d);
        assertThat(guardianService.shareAllPetsToChild(guardian, child)).isZero();
    }

    /** 공유받은 개체의 기록도 홈 캘린더·날짜 시트에 보인다 (2026-11-25 — 소유자 기준이라 빠지던 버그) */
    @Test
    void shared_pet_records_show_on_child_home_calendar() {
        Long guardian = signup();
        Long child = createChild(guardian);
        createPet(guardian, "루나"); // 첫 체중 120g 이 오늘 기록으로 남는다
        guardianService.shareAllPetsToChild(guardian, child);

        LocalDate today = LocalDate.now(java.time.ZoneId.of("Asia/Seoul"));
        String month = java.time.YearMonth.from(today).toString();
        assertThat(calendarService.getUserCalendar(child, month).days())
                .anySatisfy(d -> assertThat(d.date()).isEqualTo(today));
        assertThat(recordService.getRecordsByDate(child, today)).isNotEmpty();
        assertThat(recordService.getRecentRecords(child, 10)).isNotEmpty();
    }

    @Test
    void only_my_own_child() {
        Long guardian = signup();
        Long stranger = signup();
        Long child = createChild(guardian);
        createPet(stranger, "남의개체");

        assertThatThrownBy(() -> guardianService.shareAllPetsToChild(stranger, child))
                .isInstanceOf(BusinessException.class);
        assertThat(petKeeper.keptPetIdsOrdered(child)).isEmpty();
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "gshare" + n + "@example.com", "Passw0rd!23", "gshareparent" + n, null,
                true, true, true, null, false, null)).id();
    }

    private Long createChild(Long guardian) {
        int n = SEQ.incrementAndGet();
        return guardianService.createChild(guardian, new ChildCreateRequest(
                "gsharekid" + n + "@example.com", "Passw0rd!23", "gsharekid" + n, null,
                LocalDate.now().minusYears(10), true, false, null, null)).id();
    }

    private Long createPet(Long userId, String name) {
        return petService.create(userId, new PetCreateRequest(
                name, null, null, PetGender.MALE, null, null, null, null, null, null, null,
                120.0, null, null, null, null)).id();
    }
}
