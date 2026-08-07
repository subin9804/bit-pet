package io.bitpet.common.entitlement;

/**
 * 유료 티어 권한 판정의 단일 소스 — <b>자리만 잡아둔 인터페이스</b>다.
 *
 * <p>지금은 어떤 기능도 이걸 거치지 않고, 유일한 구현체({@link StubEntitlementService})는
 * 항상 true 를 돌려준다. 결제·구독 연동이 붙는 시점에 <b>구현체만 갈아끼우면</b> 되도록
 * 호출 지점이 인터페이스만 보게 하려는 것이다.
 *
 * <p>지금 자리를 잡아두는 이유는 하나다. 나중에 만들면 권한 판정이 화면마다 흩어진 채로
 * 시작하게 되고, 그때는 이미 늦다 — 어디가 유료 경계인지 코드에서 읽히지 않게 된다.
 */
public interface EntitlementService {

    /**
     * 이 유저가 해당 기능을 쓸 수 있는지.
     *
     * <p>구현체는 <b>실패 시 true 로 열어주는 쪽</b>을 택해야 한다. 결제 서버 장애가
     * 유료 사용자의 기능을 막는 것보다, 무료 사용자가 잠깐 더 쓰는 쪽이 낫다.
     */
    boolean hasEntitlement(Long userId, Entitlement entitlement);
}
