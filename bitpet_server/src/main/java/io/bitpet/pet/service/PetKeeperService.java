package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetKeeperRole;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.repository.PetMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 개체 접근 권한 판정의 단일 소스 (pet_keeper_rls).
 * 모든 개체 기반 서비스는 소유권 체크를 여기로 위임한다.
 *   - assertKeeper : OWNER 또는 KEEPER (기록 작성·조회·루틴 수행)
 *   - assertOwner  : OWNER 전용 (프로필 수정·삭제·공유·입분양)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetKeeperService {

    private final PetMstRepository petRepository;
    private final PetKeeperRlsRepository keeperRepository;

    /** 사육자(OWNER/KEEPER) 검증 후 개체 반환. 아니면 PET_ACCESS_DENIED */
    public PetMst assertKeeper(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!keeperRepository.existsByIdPetIdAndIdUserId(petId, userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    /** 소유자(OWNER) 검증 후 개체 반환. 아니면 PET_ACCESS_DENIED */
    public PetMst assertOwner(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        PetKeeperRls owner = keeperRepository.findOwner(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_ACCESS_DENIED));
        if (!owner.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    public boolean isKeeper(Long userId, Long petId) {
        return keeperRepository.existsByIdPetIdAndIdUserId(petId, userId);
    }

    /** 유저가 사육하는 개체 id 목록 (OWNER + KEEPER) */
    public List<Long> keptPetIds(Long userId) {
        return keeperRepository.findPetIdsByUserId(userId);
    }

    /** 개체 생성 시 소유자 등록 */
    @Transactional
    public void registerOwner(Long petId, Long userId) {
        keeperRepository.save(PetKeeperRls.of(petId, userId, PetKeeperRole.OWNER));
    }

    /** 공유 수락 시 사육자(KEEPER) 등록 */
    @Transactional
    public void registerKeeper(Long petId, Long userId) {
        keeperRepository.save(PetKeeperRls.of(petId, userId, PetKeeperRole.KEEPER));
    }
}
