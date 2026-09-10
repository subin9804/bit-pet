package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.MorphCd;
import io.bitpet.pet.dto.MorphCdResponse;
import io.bitpet.pet.repository.MorphCdRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MorphService {

    private final MorphCdRepository morphRepository;
    private final SpeciesCdRepository speciesRepository;

    /**
     * 종별 모프 목록. 공식 카탈로그 + 본인이 만든 커스텀 모프만 보인다.
     * 이 엔드포인트는 비로그인 접근이 허용되어 있어 userId 가 null 일 수 있다
     * (그 경우 커스텀 모프는 하나도 매칭되지 않아 공식 카탈로그만 나온다).
     */
    @Transactional(readOnly = true)
    public List<MorphCdResponse> listBySpecies(Long speciesId, Long userId) {
        return morphRepository.findVisibleBySpecies(speciesId, userId)
                .stream().map(MorphCdResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public List<MorphCdResponse> autocomplete(Long speciesId, String q, Long userId) {
        if (q == null || q.isBlank()) return List.of();
        return morphRepository.searchAutocomplete(speciesId, q.trim(), userId)
                .stream().map(MorphCdResponse::from).toList();
    }

    /**
     * 카탈로그에 없는 조합 모프를 직접 등록한다.
     *
     * 같은 종에 같은 이름이 이미 있으면 새로 만들지 않고 그 행을 그대로 돌려준다.
     * uq_morph_cd_species_name_ko 제약이 있어 어차피 INSERT 가 실패하고, 사용자 입장에서도
     * "이미 있는 모프를 고른 것"과 같은 결과여야 하기 때문이다. 공식 카탈로그 모프와
     * 이름이 겹치는 경우도 마찬가지로 공식 모프가 반환된다.
     */
    @Transactional
    public MorphCdResponse createCustom(Long speciesId, String rawName, Long userId) {
        String nameKo = rawName == null ? "" : rawName.trim();
        if (nameKo.isEmpty()) {
            throw new BusinessException(ErrorCode.INVALID_INPUT);
        }
        if (!speciesRepository.existsById(speciesId)) {
            throw new BusinessException(ErrorCode.SPECIES_NOT_FOUND);
        }
        return morphRepository.findBySpeciesIdAndNameKo(speciesId, nameKo)
                .map(MorphCdResponse::from)
                .orElseGet(() -> MorphCdResponse.from(
                        morphRepository.save(MorphCd.ofCustom(speciesId, nameKo, userId))));
    }
}
