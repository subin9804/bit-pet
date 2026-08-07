package io.bitpet.pet.dto;

/**
 * 개체 소유자 표시 정보 — 가계도에서 "이거 누구 개체냐"를 보여주기 위한 것.
 *
 * <p>부모 등록에는 승인·차단 절차가 없다(검증 도메인 미구현). 대신 남의 개체를 부모로
 * 걸면 그 주인이 화면에 그대로 드러나게 해서 사칭을 억제한다.
 *
 * <p><b>isMe / isOrphaned 는 서버가 판정해서 내린다.</b> 클라이언트가 currentUserId 와
 * 비교하게 두면 같은 분기가 화면마다 흩어지고, 화면마다 다르게 틀린다.
 *
 * @param userId     소유자 id. 탈퇴 익명화 개체이거나 닉네임 비공개 설정이면 null
 * @param nickname   소유자 표시명. 탈퇴 익명화 개체면 null, 비공개 설정이면 '비공개'
 * @param isMe       요청자 == 소유자
 * @param isOrphaned 소유자 없음 (user_id IS NULL 이거나 탈퇴한 계정) — 표시는 '정보 없음'
 */
public record PetOwnerResponse(
        Long userId,
        String nickname,
        boolean isMe,
        boolean isOrphaned
) {
    /** 닉네임을 감춘 소유자의 표시명. 실재하는 주인이 있다는 것까지는 드러난다 */
    public static final String HIDDEN_NICKNAME = "비공개";

    public static PetOwnerResponse orphaned() {
        return new PetOwnerResponse(null, null, false, true);
    }

    /**
     * 닉네임 비공개 — 소유자는 있지만 누구인지는 밝히지 않는다.
     * userId 도 함께 내리지 않는다. 그게 남아 있으면 앱이 프로필로 이동해 버려
     * 결국 닉네임이 드러난다(비공개 설정의 의미가 없어진다).
     */
    public static PetOwnerResponse hidden() {
        return new PetOwnerResponse(null, HIDDEN_NICKNAME, false, false);
    }

    public static PetOwnerResponse of(Long ownerUserId, String nickname, Long requesterUserId) {
        return of(ownerUserId, nickname, requesterUserId, true);
    }

    public static PetOwnerResponse of(Long ownerUserId, String nickname,
                                      Long requesterUserId, boolean showNickname) {
        if (ownerUserId == null || nickname == null) return orphaned();
        boolean isMe = ownerUserId.equals(requesterUserId);
        // 내 개체는 내 설정과 무관하게 그대로 보여준다 — 감출 상대가 나 자신은 아니다
        if (!showNickname && !isMe) return hidden();
        return new PetOwnerResponse(ownerUserId, nickname, isMe, false);
    }
}
