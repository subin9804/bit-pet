package io.bitpet.nfc.dto;

import io.bitpet.nfc.domain.TagStockStatus;

import java.time.Instant;

/**
 * 마이페이지 태그 관리용 — 내가 연결한 태그 목록.
 *
 * <p>스캔 횟수는 내려주지 않는다 (V51에서 컬럼 제거). 사용률은 클라이언트 애널리틱스로 본다.
 * 태그별 기본 동작도 없다 (V52) — 작업 종류는 태그가 아니라 그날의 작업에 종속된다.
 */
public record MyTagResponse(
        String tagCd,
        Long petId,
        String petNm,
        Instant linkedAt,
        TagStockStatus status,
        String chipType
) {}
