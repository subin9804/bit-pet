package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PetMstRepository extends JpaRepository<PetMst, Long>,
        JpaSpecificationExecutor<PetMst> {

    boolean existsBySerialNo(String serialNo);

    Optional<PetMst> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);

    Optional<PetMst> findBySerialNo(String serialNo);

    List<PetMst> findAllByUserId(Long userId);

    /** 공개 프로필용 — private_yn = 'N' 인 개체만 */
    List<PetMst> findAllByUserIdAndPrivateYn(Long userId, String privateYn);

    List<PetMst> findAllByUserIdAndSpeciesId(Long userId, Long speciesId);

    List<PetMst> findAllByUserIdAndGender(Long userId, PetGender gender);

    // 선택 필터 검색은 PetMstSpecs 로 조립한다 — "(:x IS NULL OR ...)" JPQL 을 쓰지 말 것 (LayingDtlSpecs 주석 참고)
}
