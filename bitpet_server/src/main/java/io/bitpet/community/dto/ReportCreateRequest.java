package io.bitpet.community.dto;

import io.bitpet.community.domain.ReportReason;
import io.bitpet.community.domain.ReportTargetType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 신고 접수.
 *
 * <p>{@code detail} 은 ETC 여도 강제하지 않는다. 신고는 괴로운 상황에서 누르는 버튼이라
 * 필수 입력을 늘리면 그냥 닫아버린다 — 사유 코드만으로도 운영자가 원문을 보고 판단할 수 있다.
 */
public record ReportCreateRequest(
        @NotNull ReportTargetType targetType,
        @NotNull Long targetId,
        @NotNull ReportReason reasonCd,
        @Size(max = 500) String detail
) {}
