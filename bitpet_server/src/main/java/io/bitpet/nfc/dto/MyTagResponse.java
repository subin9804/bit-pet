package io.bitpet.nfc.dto;

import io.bitpet.nfc.domain.TagActionCd;

import java.time.Instant;

/** 마이페이지 태그 관리용 — 내가 연결한 태그 목록 */
public record MyTagResponse(
        String tagCd,
        Long petId,
        String petNm,
        TagActionCd defaultActionCd,
        Instant linkedAt,
        int scanCnt,
        Instant lastScanAt
) {}
