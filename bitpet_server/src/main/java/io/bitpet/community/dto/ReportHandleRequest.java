package io.bitpet.community.dto;

import io.bitpet.community.domain.ReportAction;
import io.bitpet.community.domain.ReportStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 운영자 처리.
 *
 * <p>{@code status} 는 RESOLVED(위반 인정) 또는 REJECTED(위반 아님) 뿐이다 — PENDING 을
 * 다시 넣는 건 처리가 아니므로 엔티티가 거부한다.
 */
public record ReportHandleRequest(
        @NotNull ReportStatus status,
        @NotNull ReportAction action,
        @Size(max = 500) String memo
) {}
