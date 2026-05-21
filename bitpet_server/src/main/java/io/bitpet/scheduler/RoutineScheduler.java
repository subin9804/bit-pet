package io.bitpet.scheduler;

import io.bitpet.notification.service.NotificationService;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.repository.RoutineMstRepository;
import io.bitpet.routine.repository.RoutinePetRlsRepository;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class RoutineScheduler {

    private final RoutineMstRepository routineRepository;
    private final RoutinePetRlsRepository routinePetRepository;
    private final PetMstRepository petRepository;
    private final NotificationService notificationService;

    /**
     * 매 1분마다 만기된 루틴을 스캔하여 알림 이력을 생성하고 next_due_at을 전진.
     * 알림은 REQUIRES_NEW 트랜잭션으로 독립 처리 (실패해도 다음 루틴 계속)
     * FCM 미연동 구간: notification_log_dtl에 SENT 상태로만 기록
     */
    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void processOverdueRoutines() {
        Instant now = Instant.now();
        List<RoutineMst> overdue = routineRepository.findOverdueRoutines(now);

        if (overdue.isEmpty()) return;

        log.debug("Processing {} overdue routine(s)", overdue.size());

        for (RoutineMst routine : overdue) {
            try {
                List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routine.getId());
                if (petIds.isEmpty()) {
                    routine.advanceNextDue(now);
                    continue;
                }

                Long representativePetId = petIds.get(0);
                int petCount = petIds.size();

                String notificationTitle = buildTitle(routine, petIds);
                String notificationBody = routine.getTitle();

                notificationService.createRoutineNotification(
                        routine.getUserId(),
                        representativePetId,
                        routine.getId(),
                        petCount,
                        notificationTitle,
                        notificationBody
                );
            } catch (Exception e) {
                log.warn("Notification failed for routine id={}: {}", routine.getId(), e.getMessage());
            }
            routine.advanceNextDue(now);
        }
    }

    private String buildTitle(RoutineMst routine, List<Long> petIds) {
        String typeLabelKr = switch (routine.getRoutineType()) {
            case FEEDING  -> "밥";
            case CLEANING -> "청소";
            case WEIGHT   -> "체중 측정";
            case CUSTOM   -> routine.getTitle();
        };

        if (petIds.size() == 1) {
            PetMst pet = petRepository.findById(petIds.get(0)).orElse(null);
            String petName = pet != null ? pet.getName() : "개체";
            return petName + "의 [" + typeLabelKr + "] 시간이에요!";
        } else {
            PetMst representative = petRepository.findById(petIds.get(0)).orElse(null);
            String repName = representative != null ? representative.getName() : "개체";
            return repName + "와 " + (petIds.size() - 1) + "마리의 친구들 [" + typeLabelKr + "] 시간이에요!";
        }
    }
}
