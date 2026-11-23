package io.bitpet.pet.dto;

import java.util.List;

/**
 * 공개 프로필 — 가계도 카드의 '@닉네임', 커뮤니티 작성자 닉네임을 눌렀을 때 보이는 화면.
 *
 * <p>공개(private_yn = 'N') 개체만 싣는다. 부모로 걸린 개체가 비공개면 여기에도 안 나온다 —
 * "이 사람이 실제로 그 라인을 키우는가"를 판단할 근거는 주인이 공개한 만큼만이다.
 *
 * <p>{@code petsHidden} — 가계도 닉네임을 비공개로 둔 사람은 개체 목록을 비워서 내린다
 * (2026-11-23). 커뮤니티에선 닉네임이 원래 보이므로 프로필 자체는 열되, 여기서 개체를 보여주면
 * "이 닉네임 = 그 개체 주인"이 이어져 가계도에서 숨긴 의미가 사라진다.
 */
public record UserProfileResponse(
        Long userId,
        String nickname,
        String profileImageUrl,
        String profileColor,
        boolean isMe,
        boolean petsHidden,
        List<PetCardResponse> publicPets
) {}
