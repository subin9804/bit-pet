package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineCycleMode;
import io.bitpet.routine.domain.RoutineType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

public record RoutineUpdateRequest(
        @NotNull RoutineType routineType,
        @NotBlank @Size(max = 100) String title,
        @Positive int cycleDays,
        LocalTime alarmTime,
        boolean alarmEnabled,
        Boolean active,
        /**
         * 시작일 재설정 (생성의 {@code startAt}과 같은 자리). null 이거나 기존 시작일과
         * 같으면 일정을 건드리지 않는다 — 값이 바뀔 때만 다음 예정일이 함께 옮겨진다.
         * 이 필드가 없던 동안은 수정으로 알림 일정을 바꿀 방법이 아예 없었다.
         */
        Instant startAt,
        String memo,
        /**
         * 반복 방식. <b>null 이면 지금 방식을 유지한다</b> — 활성 토글처럼 반복 방식을 모르는
         * 호출이 요일 루틴을 간격 루틴으로 덮어쓰지 않게.
         */
        RoutineCycleMode cycleMode,
        List<Integer> daysOfWeek,
        List<Integer> daysOfMonth
) {}
