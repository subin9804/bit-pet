package io.bitpet.auth.dto;

import java.util.List;

/**
 * 탈퇴 전 미리보기 — 공동 사육자가 있는 개체를 어떻게 할지 물어보기 위한 정보.
 *
 * <p>목록이 비어 있으면 앱은 선택지를 보여주지 않고 일반 탈퇴 확인만 띄운다.
 *
 * @param sharedPets 공동 사육자가 있는 내 개체. 넘기기를 고르면 각 {@code recipientNickname} 이 받는다
 */
public record WithdrawPreviewResponse(List<SharedPet> sharedPets) {

    public int sharedPetCount() {
        return sharedPets.size();
    }

    /**
     * @param recipientNickname 넘길 경우 소유자가 될 사람 = 가장 먼저 합류한 공동 사육자.
     *                          내가 직접 초대해 함께 보던 사람이라 가계도 닉네임 공개 설정과 무관하게 그대로 보여준다
     */
    public record SharedPet(Long petId, String petName, Long recipientUserId, String recipientNickname) {}
}
