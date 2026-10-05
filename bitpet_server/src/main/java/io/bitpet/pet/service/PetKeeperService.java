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
import java.util.Optional;
import java.util.Set;

/**
 * 개체 접근 권한 판정의 단일 소스 (pet_keeper_rls).
 * 모든 개체 기반 서비스는 소유권 체크를 여기로 위임한다.
 *   - assertKeeper : OWNER 또는 KEEPER (기록·조회·루틴, 프로필 수정, 이별 표시·취소, 가계도 부모 연결·해제)
 *   - assertOwner  : OWNER 전용 (삭제·공유 초대/해제·입분양)
 *
 * <p><b>경계의 기준은 "되돌릴 수 있는가 / 소유권이 움직이는가"다.</b> 두 역할은 실질적으로
 * 공동 사육자이고 대부분 가족이라, 일상 동작을 소유자에게 묶어두면 함께 키우는 쪽이 계속 막힌다.
 * 반대로 사장-직원처럼 수직 관계일 수도 있으므로, <b>되돌릴 수 없거나 개체가 남에게 넘어가는
 * 동작만</b> 소유자에게 남긴다. 그 사이 것들(이별·가계도·프로필)은 전부 반대 동작이 있어
 * 잘못돼도 복구된다.
 *
 * <p>역할을 더 세분화(예: STAFF)하는 건 실제 수직 관계 사용자가 생긴 뒤에 한다 —
 * {@link PetKeeperRole} 에 값을 더하는 쪽이, 열어둔 권한을 나중에 회수하는 것보다 싸다.
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

    /**
     * 개체의 소유자 id. 고아 개체(주인 탈퇴)는 OWNER 행이 없어 empty 다.
     *
     * <p>권한 검사가 아니라 <b>대신 처리해 줄 대상을 찾는 용도</b>다 — 어드민이 주문 건으로
     * 태그를 미리 붙일 때 태그 소유자를 어드민이 아니라 고객으로 달아야 한다.
     */
    public Optional<Long> ownerIdOf(Long petId) {
        return keeperRepository.findOwner(petId).map(PetKeeperRls::getUserId);
    }

    /**
     * 소유자 여부. 권한 검증이 아니라 <b>응답에 실어 보낼 표시용</b>이다
     * ({@code PetResponse.isOwner} → 앱에서 삭제·분양 대상 선택 가능 여부).
     * 판정 근거는 {@link #assertOwner}와 같은 pet_keeper_rls로 맞춘다 —
     * 비정규화된 {@code pet_mst.user_id}로 판단하면 서버가 실제로 거는 검사와 어긋날 수 있다.
     */
    public boolean isOwner(Long userId, Long petId) {
        return keeperRepository.findOwner(petId)
                .map(owner -> owner.getUserId().equals(userId))
                .orElse(false);
    }

    /** 유저가 사육하는 개체 id 목록 (OWNER + KEEPER) */
    public List<Long> keptPetIds(Long userId) {
        return keeperRepository.findPetIdsByUserId(userId);
    }

    /** 유저가 소유(OWNER)한 개체 id 집합 — 목록 응답에서 개체마다 재조회하지 않으려고 한 번에 받는다 */
    public Set<Long> ownedPetIds(Long userId) {
        return keeperRepository.findOwnedByUser(userId).stream()
                .map(PetKeeperRls::getPetId)
                .collect(java.util.stream.Collectors.toSet());
    }

    // -------------------------------------------------------------------------
    // 소유 개체 상한
    // -------------------------------------------------------------------------

    /**
     * 1인당 소유할 수 있는 개체 수.
     *
     * <p>사진·기록이 개체마다 붙는 구조라 한 계정이 무제한으로 늘어나면 비용이 그대로 따라온다.
     * 값 자체는 <b>잠정</b>이다 — 막히는 사용자가 실제로 나오면 올린다. 올리는 건 상수 하나지만
     * 내리는 건 이미 넘긴 계정을 어떻게 할지부터 정해야 하므로, 넉넉하게 시작하지 않는다.
     */
    public static final int MAX_OWNED_PETS = 100;

    /** 유저가 소유한 개체 수 */
    public long countOwned(Long userId) {
        return keeperRepository.countOwnedByUser(userId);
    }

    /**
     * 개체를 하나 더 등록할 수 있는지. 넘으면 {@link ErrorCode#PET_LIMIT_EXCEEDED}.
     *
     * <p>⚠️ <b>개체가 만들어지는 모든 경로</b>가 이걸 지나야 한다 (현재 일반 등록 +
     * 산란 부화 개체 등록). 한 곳이라도 빠지면 그 경로가 상한을 우회하는 통로가 된다.
     *
     * <p>다개체 일괄 등록은 한 마리씩 {@code create} 를 호출하므로 여기서 함께 막힌다 —
     * 상한에 닿는 순간 그 뒤가 전부 실패한다. 앱이 미리 남은 수를 받아 입력을 제한하는 건
     * 안내일 뿐이고, 판정은 저장할 때 서버가 한다.
     */
    public void assertCanOwnMore(Long userId) {
        if (countOwned(userId) >= MAX_OWNED_PETS) {
            throw new BusinessException(ErrorCode.PET_LIMIT_EXCEEDED);
        }
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
