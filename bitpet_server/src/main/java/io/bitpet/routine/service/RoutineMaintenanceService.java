package io.bitpet.routine.service;

import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.repository.RoutineMstRepository;
import io.bitpet.routine.repository.RoutinePetRlsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 루틴-개체 연결 유지보수.
 * 개체 접근권 변화(공유 해제·입분양·개체 삭제) 시 루틴에서 연결을 정리하고
 * "연결된 '내' 개체가 0개면 비활성, 1개 이상이면 활성" 규칙에 따라 is_active를 토글한다.
 */
@Service
@RequiredArgsConstructor
public class RoutineMaintenanceService {

    private final RoutinePetRlsRepository routinePetRepository;
    private final RoutineMstRepository routineRepository;
    private final PetKeeperRlsRepository keeperRepository;

    /**
     * 유저가 개체 접근권을 잃음(입분양으로 소유 이전·공유 해제).
     * 그 유저 소유 루틴에서 해당 개체 연결을 제거하고 활성 상태를 재계산한다.
     */
    @Transactional
    public void onKeeperAccessLost(Long userId, Long petId) {
        List<Long> routineIds = routinePetRepository.findRoutineIdsByPetIdAndOwner(petId, userId);
        for (Long routineId : routineIds) {
            routinePetRepository.deleteByRoutineIdAndPetId(routineId, petId);
            refreshActive(routineId);
        }
    }

    /**
     * 개체가 완전히 삭제됨. 그 개체에 연결된 모든 소유자의 루틴에서 연결을 제거하고 재계산한다.
     */
    @Transactional
    public void onPetDeleted(Long petId) {
        List<Long> routineIds = routinePetRepository.findRoutineIdsByPetId(petId);
        for (Long routineId : routineIds) {
            routinePetRepository.deleteByRoutineIdAndPetId(routineId, petId);
            refreshActive(routineId);
        }
    }

    /** 루틴의 연결 개체 중 소유자가 여전히 사육 중인 개체 수 → is_active 토글 */
    @Transactional
    public void refreshActive(Long routineId) {
        RoutineMst routine = routineRepository.findById(routineId).orElse(null);
        if (routine == null) return;
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        boolean hasKeptPet = petIds.stream()
                .anyMatch(petId -> keeperRepository.existsByIdPetIdAndIdUserId(petId, routine.getUserId()));
        routine.setActiveState(hasKeptPet);
    }
}
