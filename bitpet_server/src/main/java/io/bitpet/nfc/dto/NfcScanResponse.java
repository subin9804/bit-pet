package io.bitpet.nfc.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.bitpet.nfc.domain.TagStatus;
import io.bitpet.pet.dto.PetCardResponse;

/**
 * 태그 스캔 결과 (GET /api/v1/nfc/tags/{tagCd}/resolve).
 *
 * <p>기존 {@link TagResolveResponse} 와 다른 점은 하나다 — 개체 정보를 카드로 함께 내려준다.
 * 스캔 시트가 "이 개체가 맞나요?"를 그 자리에서 보여줘야 하는데, 그러려면 개체명·종·모프·성별·
 * 해칭일이 필요하다. 개체 상세를 한 번 더 부르면 남의 개체에선 403 이 난다.
 *
 * <p><b>남의 개체일 때의 필드 축소는 서버가 한다.</b> {@link PetCardResponse} 자체가
 * "남에게 보여도 되는 전부"로 설계된 DTO라 사육기록·체중·커뮤니티 활동은 애초에 담기지 않고,
 * 소유자 정보({@code owner})는 OWNED_BY_OTHER 에서 {@code null} 로 비워 내보낸다.
 * 클라이언트에 숨김을 맡기지 않는다 — 숨김은 응답을 까 보면 무너진다.
 *
 * @param status LINKED / UNLINKED / OWNED_BY_OTHER / REVOKED
 * @param pet    LINKED·OWNED_BY_OTHER 일 때만. 그 외에는 null
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record NfcScanResponse(
        TagStatus status,
        String tagCd,
        PetCardResponse pet
) {
    public static NfcScanResponse unlinked(String tagCd) {
        return new NfcScanResponse(TagStatus.UNLINKED, tagCd, null);
    }

    public static NfcScanResponse revoked(String tagCd) {
        return new NfcScanResponse(TagStatus.REVOKED, tagCd, null);
    }

    public static NfcScanResponse linked(String tagCd, PetCardResponse pet) {
        return new NfcScanResponse(TagStatus.LINKED, tagCd, pet);
    }

    public static NfcScanResponse ownedByOther(String tagCd, PetCardResponse pet) {
        return new NfcScanResponse(TagStatus.OWNED_BY_OTHER, tagCd, pet);
    }
}
