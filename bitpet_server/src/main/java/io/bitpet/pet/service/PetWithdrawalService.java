package io.bitpet.pet.service;

import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.repository.RoutineMstRepository;
import io.bitpet.routine.service.RoutineMaintenanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 회원 탈퇴 시 개체 소유권 정리.
 * "이 앱의 본질은 기록" — 소유자가 탈퇴하면 개체를 지우지 않고 KEEPER 중 하나를 OWNER로 승격한다.
 * 승격할 KEEPER가 없으면 개체를 soft-delete 한다. 탈퇴 시 입분양을 유도하지는 않는다.
 */
@Service
@RequiredArgsConstructor
public class PetWithdrawalService {

    private final PetKeeperRlsRepository keeperRepository;
    private final PetMstRepository petRepository;
    private final RoutineMstRepository routineRepository;
    private final RoutineMaintenanceService routineMaintenance;

    @Transactional
    public void handleUserWithdrawal(Long userId) {
        // 1) 소유(OWNER) 개체 — KEEPER 승격 또는 soft-delete
        for (PetKeeperRls owned : keeperRepository.findOwnedByUser(userId)) {
            Long petId = owned.getPetId();
            List<PetKeeperRls> keepers = keeperRepository.findKeepers(petId); // KEEPER, 합류 순
            keeperRepository.delete(owned); // 탈퇴자의 소유 행 제거

            if (!keepers.isEmpty()) {
                PetKeeperRls promoted = keepers.get(0);
                promoted.promoteToOwner();
                petRepository.findById(petId)
                        .ifPresent(p -> p.transferOwnerTo(promoted.getUserId()));
            } else {
                petRepository.findById(petId).ifPresent(PetMst::softDelete);
                routineMaintenance.onPetDeleted(petId);
            }
        }

        // 2) 남은 KEEPER 행(타인 소유 개체 공유분) 제거
        keeperRepository.findAllByIdUserId(userId).forEach(keeperRepository::delete);

        // 3) 탈퇴자의 개인 루틴 soft-delete (스케줄러 알림 방지)
        for (RoutineMst routine : routineRepository.findAllByUserIdOrderByCreatedAtDesc(userId)) {
            routine.softDelete();
        }
    }
}
