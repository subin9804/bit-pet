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
 * 루틴 수정 시의 일정 재설정 — 시작일 이동 + '오늘 보냄' 표시 해제.
 *
 * <p>여기서 틀리면 증상이 "루틴을 고쳤는데 알림이 안 온다" 또는 "편집했더니 예정일이
 * 시작일로 되감겼다"로 나타난다. 둘 다 에러 없이 조용히 어긋난다.
 */
class RoutineRescheduleTest {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private static LocalDate today() {
        return LocalDate.now(SEOUL);
    }

    private static RoutineMst routine(LocalDate startDate, LocalDate nextDueAt) {
        return RoutineMst.builder()
                .userId(1L)
                .routineType(RoutineType.FEEDING)
                .title("사료 급여")
                .cycleDays(7)
                .alarmTime(LocalTime.of(9, 0))
                .alarmEnabled(true)
                .startDate(startDate)
                .nextDueAt(nextDueAt)
                .build();
    }

    /** 기존 값 그대로 보내는 '다른 필드만 수정' 호출 */
    private static void updateKeepingAlarm(RoutineMst r) {
        r.update(r.getRoutineType(), "제목만 바꿈", r.getCycleDays(),
                r.getAlarmTime(), r.isAlarmEnabled(), null, r.getMemo());
    }

    // ── 시작일 재설정 ────────────────────────────────────────────────────────

    @Test
    @DisplayName("시작일을 바꾸면 다음 예정일도 함께 옮겨진다")
    void rescheduleMovesBothDates() {
        RoutineMst r = routine(today().minusDays(30), today().plusDays(5));

        r.reschedule(today());

        assertThat(r.getStartDate()).isEqualTo(today());
        assertThat(r.getNextDueAt()).isEqualTo(today());
    }

    @Test
    @DisplayName("같은 시작일이 다시 와도 예정일은 건드리지 않는다 — 폼 전체 전송이 일정을 되감지 못하게")
    void rescheduleWithSameDateIsNoOp() {
        LocalDate start = today().minusDays(30);
        LocalDate due   = today().plusDays(5);
        RoutineMst r = routine(start, due);

        r.reschedule(start);   // 앱이 수정 시 바뀌지 않은 시작일도 함께 보낸다
        r.reschedule(null);    // 필드를 아예 안 보낸 경우

        assertThat(r.getNextDueAt()).isEqualTo(due);
        assertThat(r.getStartDate()).isEqualTo(start);
    }

    @Test
    @DisplayName("시작일을 바꾸면 미룸 표시가 지워진다 — 되돌릴 기준이 되는 옛 일정이 사라졌다")
    void rescheduleClearsPostponedMark() {
        RoutineMst r = routine(today().minusDays(10), today());
        r.postpone(today().plusDays(3), Instant.now());

        r.reschedule(today().plusDays(1));

        assertThat(r.getPostponedAt()).isNull();
        assertThat(r.getPostponedFrom()).isNull();
        assertThat(r.cancelPostpone()).isFalse();
    }

    // ── '오늘 보냄' 표시 해제 ─────────────────────────────────────────────────

    @Test
    @DisplayName("알람 시각이 그대로면 '오늘 보냄' 표시를 유지한다 — 제목만 고쳐도 알림이 또 오면 안 된다")
    void updateWithoutAlarmChangeKeepsNotifiedMark() {
        RoutineMst r = routine(today(), today());
        Instant notified = Instant.now();
        r.markNotified(notified);

        updateKeepingAlarm(r);

        assertThat(r.getLastNotifiedAt()).isEqualTo(notified);
    }

    @Test
    @DisplayName("알람을 끄면(시각 null) '오늘 보냄' 표시가 지워진다")
    void turningAlarmOffClearsNotifiedMark() {
        RoutineMst r = routine(today(), today());
        r.markNotified(Instant.now());

        r.update(r.getRoutineType(), r.getTitle(), r.getCycleDays(),
                null, false, null, r.getMemo());

        assertThat(r.getLastNotifiedAt()).isNull();
    }

    @Test
    @DisplayName("시작일 재설정도 '오늘 보냄' 표시를 지운다")
    void rescheduleClearsNotifiedMarkWhenAlarmStillAhead() {
        // 알람 23:59 — 호출 시점이 그보다 앞이면 지워야 한다
        RoutineMst r = RoutineMst.builder()
                .userId(1L).routineType(RoutineType.FEEDING).title("사료 급여")
                .cycleDays(7).alarmTime(LocalTime.of(23, 59)).alarmEnabled(true)
                .startDate(today().minusDays(7)).nextDueAt(today()).build();
        r.markNotified(Instant.now());

        r.reschedule(today().plusDays(1));

        // 23:59 는 실행 시각보다 뒤다 (하루의 마지막 1분에 돌리지 않는 한)
        assertThat(r.getLastNotifiedAt()).isNull();
    }

    /**
     * 시각 분기는 순수 함수로 직접 본다 — {@code update()} 를 통해 보면 테스트가
     * 실행된 벽시계 시각에 따라 결과가 갈려 흔들린다.
     */
    @Test
    @DisplayName("아직 안 지난 알람으로 옮기면 표시를 지우고, 이미 지난 알람이면 유지한다")
    void forgetDecisionDependsOnWhetherNewAlarmHasPassed() {
        LocalTime now = LocalTime.of(18, 0);

        // 18시에 알람을 20시로 옮김 → 오늘 20시에 와야 한다
        assertThat(RoutineMst.shouldForgetTodaysNotification(LocalTime.of(20, 0), now)).isTrue();

        // 18시에 알람을 9시로 옮김 → 지우면 저장하는 순간 알림이 튀어나온다.
        // 사용자가 기대하는 건 '내일 9시'다
        assertThat(RoutineMst.shouldForgetTodaysNotification(LocalTime.of(9, 0), now)).isFalse();

        // 딱 지금이면 지운다 (스케줄러 조건이 alarmTime <= now 라 바로 발사된다)
        assertThat(RoutineMst.shouldForgetTodaysNotification(now, now)).isTrue();

        // 알람을 끈 경우 — 어차피 발사 대상이 아니므로 지워도 무해하다
        assertThat(RoutineMst.shouldForgetTodaysNotification(null, now)).isTrue();
    }
}
