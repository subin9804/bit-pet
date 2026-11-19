package io.bitpet.nfc.dto;

import io.bitpet.pet.dto.PetCardResponse;

/**
 * 이름표로 찍은 개체의 프로필 (GET /api/v1/nfc/tags/{tagCd}/profile).
 *
 * <p>남의 개체를 스캔했을 때 "이미 등록된 이름표" 한 줄로 끝내지 않고 개체를 보여주기 위한 응답이다.
 * <b>비공개 개체도 연다</b> — 실물 이름표를 손에 쥔 사람만 닿는 경로라서다(코드는 6자 랜덤이라 추측 불가).
 *
 * <p>담는 건 카드({@link PetCardResponse} — 이름·종·모프·성별·해칭일·대표사진)와 <b>최신 체중 하나</b>뿐이다.
 * 갤러리는 한때 넣었다가 뺐다(사용자 결정, 2026-11-20) — 대표사진 한 장이면 충분하다.
 * ⛔ 갤러리·사육기록·체중 이력·메모·루틴은 넣지 않는다. 소유자({@code pet.owner})도 남에게는 비워 내보낸다.
 */
public record NfcPetProfileResponse(
        PetCardResponse pet,
        /** 가장 최근 체중(g). 기록이 없으면 null */
        Double latestWeightG
) {}
