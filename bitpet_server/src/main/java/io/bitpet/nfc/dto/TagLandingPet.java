package io.bitpet.nfc.dto;

import java.util.List;

/**
 * 미설치자 랜딩 페이지에 보여줄 개체 정보.
 *
 * <p><b>노출 범위</b> — 이름표에 이미 적혀 있을 법한 것까지만.
 * 체중·급여·청소 같은 사육 기록, 생일·입양일, 주인 정보는 절대 포함하지 않는다.
 */
public record TagLandingPet(
        String name,
        String speciesName,
        List<String> morphNames,
        String genderLabel,   // 수컷 / 암컷 / null(미구분)
        String imageUrl       // 대표 사진 (없으면 null)
) {}
