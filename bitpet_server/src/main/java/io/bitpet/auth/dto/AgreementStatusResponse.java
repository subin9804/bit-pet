package io.bitpet.auth.dto;

import io.bitpet.auth.domain.AgreementType;

import java.time.Instant;
import java.util.List;

/**
 * 현재 동의 상태.
 *
 * <p>{@code needsReagreement} 는 "동의는 했는데 그 뒤에 약관이 개정된" 상태다.
 * 앱은 이 값이 true 인 필수 항목이 하나라도 있으면 재동의 화면을 띄워야 한다.
 */
public record AgreementStatusResponse(
        List<Item> items,
        boolean needsReagreement
) {
    public record Item(
            AgreementType type,
            boolean required,
            boolean agreed,
            String agreedVersion,
            String currentVersion,
            Instant agreedAt
    ) {
        public boolean outdated() {
            return agreed && agreedVersion != null
                    && !agreedVersion.equals(currentVersion);
        }
    }

    public static AgreementStatusResponse of(List<Item> items) {
        boolean needs = items.stream()
                .anyMatch(i -> i.required() && (!i.agreed() || i.outdated()));
        return new AgreementStatusResponse(items, needs);
    }
}
