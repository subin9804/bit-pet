package io.bitpet.nfc.dto;

import io.bitpet.pet.dto.PetCardResponse;
import io.bitpet.pet.dto.PetOwnerResponse;

import java.util.List;

/**
 * 이름표로 찍은 개체의 프로필 (GET /api/v1/nfc/tags/{tagCd}/profile).
 *
 * <p>남의 개체를 스캔했을 때 "이미 등록된 이름표" 한 줄로 끝내지 않고 개체를 보여주기 위한 응답이다.
 * <b>비공개 개체도 연다</b> — 실물 이름표를 손에 쥔 사람만 닿는 경로라서다(코드는 6자 랜덤이라 추측 불가).
 *
 * <p>담는 건 카드({@link PetCardResponse} — 이름·종·모프·성별·해칭일·대표사진)와 <b>최신 체중 하나</b>뿐이다.
 * 갤러리는 한때 넣었다가 뺐다(사용자 결정, 2026-11-20) — 대표사진 한 장이면 충분하다.
 * ⛔ 갤러리·사육기록·체중 이력·메모·루틴은 넣지 않는다. 카드 안의 소유자({@code pet.owner})는 남에게 비워 내보낸다.
 *
 * <p>부모 카드도 싣는다 (2026-11-24, {@link #parents}) — 해칭일과 함께 "어디서 온 개체인지"가 남의 개체에서 가장 궁금한 값이다.
 *
 * <p>소유자는 {@link #owner} 로 따로 싣는다 (2026-11-23) — 앱이 "소유자 프로필" 버튼을 단다.
 * 가계도와 같은 규칙이다: 닉네임을 감춘 사람·차단 관계면 userId 없이 내려 프로필로 못 간다.
 */
public record NfcPetProfileResponse(
        PetCardResponse pet,
        /** 가장 최근 체중(g). 기록이 없으면 null */
        Double latestWeightG,
        /** 개체 소유자. 닉네임 비공개·차단 관계면 userId 가 null ({@link PetOwnerResponse#hidden()}) */
        PetOwnerResponse owner,
        /**
         * 부모 카드 (2026-11-24). 가계도의 부모 줄과 같은 카드 규칙(사육 기록 제외)이다 —
         * relationType(FATHER/MOTHER)으로 부·모를 가른다. 등록된 부모가 없으면 빈 목록.
         * ⛔ 조부모·자식·동배는 싣지 않는다 — 남의 번식 이력까지 이름표로 드러낼 이유가 없다.
         */
        List<PetCardResponse> parents
) {}
