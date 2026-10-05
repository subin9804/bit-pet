package io.bitpet.pet.dto;

/**
 * 소유 개체 수 / 상한 / 남은 수.
 *
 * <p>{@code remaining} 을 앱이 직접 빼서 쓰지 않게 서버가 내려준다 — 상한이 바뀌었을 때
 * 구버전 앱이 옛 상수로 계산하면 "남았다는데 저장이 안 되는" 화면이 된다.
 */
public record PetQuotaResponse(
        long owned,
        int max,
        long remaining
) {}
