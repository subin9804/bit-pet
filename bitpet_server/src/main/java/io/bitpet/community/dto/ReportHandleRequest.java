package io.bitpet.community.dto;

import io.bitpet.community.domain.ReportAction;
import io.bitpet.community.domain.ReportStatus;
import io.bitpet.community.domain.SuspensionDuration;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 운영자 처리.
 *
 * <p>{@code status} 는 RESOLVED(위반 인정) 또는 REJECTED(위반 아님) 뿐이다 — PENDING 을
 * 다시 넣는 건 처리가 아니므로 엔티티가 거부한다.
 *
 * <p>{@code suspendDuration} 은 action 이 SUSPEND 일 때만 본다 (1일/7일/30일/영구).
 */
public record ReportHandleRequest(
        @NotNull ReportStatus status,
        @NotNull ReportAction action,
        @Size(max = 500) String memo,
        SuspensionDuration suspendDuration
) {}
