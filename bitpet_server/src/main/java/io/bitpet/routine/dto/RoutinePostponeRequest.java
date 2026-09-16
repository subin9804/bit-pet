package io.bitpet.routine.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

/**
 * 루틴 미루기 — 다음 예정일을 이 날짜로 옮긴다 (Asia/Seoul 기준 내일 이후).
 * 루틴 단위 동작이라 연결된 모든 개체의 예정일이 함께 밀린다.
 */
public record RoutinePostponeRequest(
        @NotNull LocalDate nextDueAt
) {}
