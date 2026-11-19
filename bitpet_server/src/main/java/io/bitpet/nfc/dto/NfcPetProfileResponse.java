package io.bitpet.nfc.dto;

import io.bitpet.pet.dto.PetCardResponse;

import java.time.Instant;
import java.util.List;

/**
 * 이름표로 찍은 개체의 프로필 (GET /api/v1/nfc/tags/{tagCd}/profile).
 *
 * <p>남의 개체를 스캔했을 때 "이미 등록된 이름표" 한 줄로 끝내지 않고 개체를 보여주기 위한 응답이다.
 * <b>비공개 개체도 연다</b> — 실물 이름표를 손에 쥔 사람만 닿는 경로라서다(코드는 6자 랜덤이라 추측 불가).
 *
 * <p>담는 건 카드({@link PetCardResponse} — 이름·종·모프·성별·해칭일·대표사진)와 <b>갤러리 사진</b>뿐이다.
 * ⛔ 사육기록·체중·메모·루틴은 넣지 않는다. 소유자({@code pet.owner})도 남에게는 비워 내보낸다.
 * 사진도 URL·날짜·태그만 — 파일 크기·해상도 같은 메타는 화면에 필요 없다.
 */
public record NfcPetProfileResponse(
        PetCardResponse pet,
        List<Photo> photos
) {
    public record Photo(
            Long photoId,
            String url,
            /** 축소본. null 이면 앱이 {@code url} 로 폴백한다 */
            String thumbnailUrl,
            String caption,
            Instant createdAt
    ) {}
}
