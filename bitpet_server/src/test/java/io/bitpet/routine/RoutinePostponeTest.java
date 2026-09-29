package io.bitpet.routine;

import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 미루기 / 되돌리기 — 순수 도메인 규칙.
 *
 * <p>Testcontainers 없이 도는 단위 테스트다. 여기서 검증하는 건 날짜 계산 규칙이고,
 * 그 규칙이 틀리면 사용자 예정일이 조용히 어긋난다(에러가 안 난다).
 */
class RoutinePostponeTest {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private static LocalDate today() {
        return LocalDate.now(SEOUL);
    }

    private static RoutineMst routine(LocalDate nextDueAt) {
        return RoutineMst.builder()
                .userId(1L)
                .routineType(RoutineType.FEEDING)
                .title("사료 급여")
                .cycleDays(7)
                .alarmTime(LocalTime.of(9, 0))
                .alarmEnabled(true)
                .startDate(nextDueAt)
                .nextDueAt(nextDueAt)
                .build();
    }

    @Test
    @DisplayName("미루면 직전 예정일이 postponedFrom 에 남는다")
    void postponeRemembersPreviousDueDate() {
        LocalDate due = today();
        RoutineMst r = routine(due);

        r.postpone(due.plusDays(6), Instant.now());

        assertThat(r.getNextDueAt()).isEqualTo(due.plusDays(6));
        assertThat(r.getPostponedFrom()).isEqualTo(due);
        assertThat(r.getPostponedAt()).isNotNull();
    }

    @Test
    @DisplayName("되돌리면 직전 예정일로 돌아가고 미룸 표시가 지워진다")
    void cancelRestoresPreviousDueDate() {
        LocalDate due = today().plusDays(3);   // 아직 안 지난 날짜
        RoutineMst r = routine(due);
        r.postpone(due.plusDays(6), Instant.now());

        assertThat(r.cancelPostpone()).isTrue();

        assertThat(r.getNextDueAt()).isEqualTo(due);
        assertThat(r.getPostponedAt()).isNull();
        assertThat(r.getPostponedFrom()).isNull();
    }

    @Test
    @DisplayName("되돌릴 날짜가 이미 지났으면 오늘로 당긴다 — 과거 날짜를 그대로 넣으면 롤오버가 앞으로 밀어버린다")
    void cancelClampsPastDueDateToToday() {
        LocalDate due = today().minusDays(4);   // 이미 지난 예정일에서 미뤘던 경우
        RoutineMst r = routine(due);
        r.postpone(today().plusDays(5), Instant.now());

        assertThat(r.cancelPostpone()).isTrue();
        assertThat(r.getNextDueAt()).isEqualTo(today());

        // 되돌린 날짜가 과거가 아니므로 자정 롤오버가 건드리지 않는다.
        r.advanceDueDate();
        assertThat(r.getNextDueAt()).isEqualTo(today());
    }

    @Test
    @DisplayName("미룬 적 없으면 되돌릴 게 없다 (서비스가 409 로 바꾼다)")
    void cancelWithoutPostponeDoesNothing() {
        LocalDate due = today().plusDays(2);
        RoutineMst r = routine(due);

        assertThat(r.cancelPostpone()).isFalse();
        assertThat(r.getNextDueAt()).isEqualTo(due);
    }

    @Test
    @DisplayName("되돌리기는 마지막 1회만 — 두 번 미루면 중간 날짜까지만 돌아간다")
    void cancelOnlyUndoesTheLastPostpone() {
        LocalDate due = today().plusDays(1);
        RoutineMst r = routine(due);

        r.postpone(due.plusDays(3), Instant.now());   // 1차
        r.postpone(due.plusDays(9), Instant.now());   // 2차 — postponedFrom 이 덮어써진다

        assertThat(r.cancelPostpone()).isTrue();
        assertThat(r.getNextDueAt()).isEqualTo(due.plusDays(3));   // 최초 due 가 아니다

        // 한 번 되돌리면 표시가 지워지므로 더 되돌릴 수 없다.
        assertThat(r.cancelPostpone()).isFalse();
    }

    @Test
    @DisplayName("루틴을 실제로 완료하면 미룸 표시가 해제된다")
    void completingClearsPostponedMark() {
        LocalDate due = today();
        RoutineMst r = routine(due);
        r.postpone(due.plusDays(4), Instant.now());

        r.markExecuted(Instant.now());

        assertThat(r.getPostponedAt()).isNull();
        assertThat(r.getPostponedFrom()).isNull();
        assertThat(r.cancelPostpone()).isFalse();
    }
}
