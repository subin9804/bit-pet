package io.bitpet.common.entitlement;

import org.springframework.stereotype.Service;

/**
 * 유료화 이전의 기본 구현 — 전부 허용.
 *
 * <p>결제 연동이 붙으면 이 클래스를 대체한다({@code @ConditionalOnMissingBean} 이 아니라
 * 명시적으로 교체한다 — 어느 구현이 도는지가 조건식에 숨으면 안 된다).
 */
@Service
public class StubEntitlementService implements EntitlementService {

    @Override
    public boolean hasEntitlement(Long userId, Entitlement entitlement) {
        return true;
    }
}
