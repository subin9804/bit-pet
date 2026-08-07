package io.bitpet.nfc.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.bitpet.nfc.domain.TagStatus;

/**
 * 태그 스캔 결과. 앱은 {@code status} 로만 분기한다.
 *
 * <p>남의 태그일 때는 개체 정보를 일절 내려주지 않는다.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record TagResolveResponse(
        TagStatus status,
        String tagCd,
        Long petId,
        String petNm
) {
    public static TagResolveResponse unlinked(String tagCd) {
        return new TagResolveResponse(TagStatus.UNLINKED, tagCd, null, null);
    }

    public static TagResolveResponse linked(String tagCd, Long petId, String petNm) {
        return new TagResolveResponse(TagStatus.LINKED, tagCd, petId, petNm);
    }

    public static TagResolveResponse ownedByOther(String tagCd) {
        return new TagResolveResponse(TagStatus.OWNED_BY_OTHER, tagCd, null, null);
    }

    /** 차단된 태그 — 404 로 뭉개지 않고 이유를 알려준다 */
    public static TagResolveResponse revoked(String tagCd) {
        return new TagResolveResponse(TagStatus.REVOKED, tagCd, null, null);
    }
}
