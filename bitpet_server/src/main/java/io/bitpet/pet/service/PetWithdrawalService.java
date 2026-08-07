package io.bitpet.pet.service;

import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.repository.PetKeeperRlsRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetPurgeRepository;
import io.bitpet.pet.repository.PetRelationRlsRepository;
import io.bitpet.record.mating.repository.MatingDtlRepository;
import io.bitpet.routine.service.RoutineMaintenanceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;

/**
 * 회원 탈퇴 시 개체 처리.
 *
 * <p>순서가 핵심이다.
 * <ol>
 *   <li>탈퇴 회원 개체끼리의 가계도·메이팅을 <b>먼저</b> 지운다. 이걸 하지 않으면
 *       "가입 후 자기 개체 몇 마리를 서로 연결하고 바로 탈퇴한" 계정의 개체가 서로를
 *       참조한다는 이유로 전부 보존돼 쓰레기 데이터가 된다. 이 단계를 지나면 남는 참조는
 *       <b>타 사용자 데이터가 거는 것</b>뿐이다.</li>
 *   <li>개체별 잔여 참조 검사 — 남의 가계도가 부모로 걸었거나, 메이팅 상대로 걸었거나.</li>
 *   <li>참조 0건이면 완전 삭제, 1건 이상이면 익명화 보존.</li>
 * </ol>
 *
 * <p>전체가 하나의 트랜잭션이어야 하므로 {@code MANDATORY} 로 선언해 호출부
 * ({@code AuthService.withdraw})의 트랜잭션에만 참여한다. S3 삭제만 커밋 뒤로 미룬다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PetWithdrawalService {

    private final PetKeeperRlsRepository keeperRepository;
    private final PetMstRepository petRepository;
    private final PetRelationRlsRepository relationRepository;
    private final MatingDtlRepository matingRepository;
    private final PetPurgeRepository purgeRepository;
    private final RoutineMaintenanceService routineMaintenance;
    private final PetPurgeService petPurge;

    /** 탈퇴 처리 결과 — 로그·운영 확인용 */
    public record Result(int purged, int anonymized, int handedOver, int keeperReleased) {}

    @Transactional(propagation = Propagation.MANDATORY)
    public Result process(Long userId) {
        List<Long> ownedPetIds = keeperRepository.findOwnedByUser(userId).stream()
                .map(PetKeeperRls::getPetId)
                .toList();

        // ① 자기 개체끼리의 상호 참조 제거 (빈 IN 절은 JPQL 에서 문법 오류라 더미 id 를 넣는다)
        Collection<Long> scope = ownedPetIds.isEmpty() ? List.of(-1L) : ownedPetIds;
        relationRepository.deleteIntraAccountRelations(scope);
        matingRepository.deleteOwnedByUser(userId, scope);

        int purged = 0, anonymized = 0, handedOver = 0;
        for (Long petId : ownedPetIds) {
            // 공동 사육자가 있으면 개체를 지우지도 익명화하지도 않는다 — 넘긴다.
            // 남의 기록이 얹혀 있는 개체를 탈퇴 한 번으로 날려버릴 수는 없다.
            List<PetKeeperRls> keepers = keeperRepository.findKeepers(petId);
            if (!keepers.isEmpty()) {
                handOver(userId, petId, keepers.get(0));
                handedOver++;
                continue;
            }

            // ② 잔여 참조 검사 — ① 이후라 여기 걸리는 건 전부 타 사용자 데이터다
            boolean referenced = relationRepository.existsByParentPetId(petId)
                    || matingRepository.existsReferenceTo(petId);

            // ③ 분기
            if (referenced) {
                if (petPurge.anonymize(petId)) anonymized++;
                else purged++;
            } else {
                petPurge.purge(petId);
                purged++;
            }
        }

        // 공유받아 사육 중이던 남의 개체 — 접근권만 내려놓는다
        int keeperReleased = releaseKeptPets(userId);

        // 개체가 아니라 사람에게 달린 데이터
        purgeRepository.deleteRoutinesOfUser(userId);
        purgeRepository.deleteDeviceTokensOfUser(userId);
        purgeRepository.deleteNotificationLogsOfUser(userId);
        purgeRepository.deleteShareInvitationsOfUser(userId);

        Result result = new Result(purged, anonymized, handedOver, keeperReleased);
        log.info("Withdrawal pet processing done: userId={}, {}", userId, result);
        return result;
    }

    /**
     * 소유권 이전 — 가장 먼저 합류한 공동 사육자를 소유자로 승격시킨다.
     * 개체·기록·사진은 그대로 두고, 탈퇴 회원의 사육자 행과 루틴 연결만 걷어낸다.
     */
    private void handOver(Long userId, Long petId, PetKeeperRls newOwner) {
        newOwner.promoteToOwner();
        keeperRepository.deleteByIdPetIdAndIdUserId(petId, userId);
        petRepository.findById(petId).ifPresent(p -> p.transferOwnerTo(newOwner.getUserId()));
        routineMaintenance.onKeeperAccessLost(userId, petId);
        log.info("Pet handed over on withdrawal: petId={}, from={}, to={}",
                petId, userId, newOwner.getUserId());
    }

    /** 탈퇴 회원이 KEEPER 로만 참여하던 개체에서 빠진다 (개체는 소유자 것이므로 손대지 않는다) */
    private int releaseKeptPets(Long userId) {
        List<PetKeeperRls> rows = keeperRepository.findAllByIdUserId(userId).stream()
                .filter(row -> !row.isOwner())
                .toList();
        for (PetKeeperRls row : rows) {
            routineMaintenance.onKeeperAccessLost(userId, row.getPetId());
            keeperRepository.delete(row);
        }
        return rows.size();
    }

    /**
     * 고아 개체 정리 한 라운드 — 더 이상 아무도 참조하지 않는 익명화 개체를 물리 삭제한다.
     *
     * <p>한 마리를 지우면 그 개체가 부모로 걸고 있던 행도 함께 사라져, 위 세대가 새로 참조 0이
     * 될 수 있다. 그래서 배치는 이 메서드를 <b>더 지울 게 없을 때까지 반복</b> 호출한다.
     * 라운드마다 트랜잭션을 끊는 건 연쇄가 길어졌을 때 한 트랜잭션이 무한정 커지지 않게 하려는 것이다.
     *
     * @return 이번 라운드에 삭제한 개체 수
     */
    @Transactional
    public int cleanupUnreferencedOrphans(int limit) {
        List<Long> ids = purgeRepository.findUnreferencedOrphanIds(limit);
        for (Long petId : ids) {
            petPurge.purge(petId);
        }
        return ids.size();
    }
}
