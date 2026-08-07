package io.bitpet.pet.dto;

import java.util.List;

/**
 * 공개 프로필 — 가계도 카드의 '@닉네임'을 눌렀을 때 보이는 화면.
 *
 * <p>공개(private_yn = 'N') 개체만 싣는다. 부모로 걸린 개체가 비공개면 여기에도 안 나온다 —
 * "이 사람이 실제로 그 라인을 키우는가"를 판단할 근거는 주인이 공개한 만큼만이다.
 */
public record UserProfileResponse(
        Long userId,
        String nickname,
        String profileImageUrl,
        boolean isMe,
        List<PetCardResponse> publicPets
) {}
