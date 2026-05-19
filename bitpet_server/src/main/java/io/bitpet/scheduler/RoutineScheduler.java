package io.bitpet.scheduler;

import io.bitpet.notification.service.NotificationService;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.repository.RoutineMstRepository;
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
    private final PetMstRepository petRepository;
    private final NotificationService notificationService;

    /**
     * 매 1분마다 만기된 루틴을 스캔하여 DB 알림 이력을 생성하고 다음 예정일을 앞당긴다.
     * - 알림 생성은 REQUIRES_NEW 트랜잭션으로 독립 처리 (실패해도 다음 루틴 계속)
     * - 알림 성공/실패 무관하게 next_due_at은 항상 전진 (중복 알림 방지)
     * - FCM 미연동 구간: notification_log_dtl에 SENT 상태로만 기록
     */
    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void processOverdueRoutines() {
        Instant now = Instant.now();
        List<RoutineMst> overdue = routineRepository.findOverdueRoutines(now);

        if (overdue.isEmpty()) return;

        log.debug("Processing {} overdue routine(s)", overdue.size());

        for (RoutineMst routine : overdue) {
            PetMst pet = petRepository.findById(routine.getPetId()).orElse(null);
            if (pet != null) {
                try {
                    notificationService.createRoutineNotification(
                            pet.getUserId(),
                            routine.getPetId(),
                            routine.getId(),
                            "[루틴 알림] " + routine.getTitle(),
                            routine.getTitle() + " 루틴을 수행할 시간입니다."
                    );
                } catch (Exception e) {
                    log.warn("Notification failed for routine id={}: {}", routine.getId(), e.getMessage());
                }
            }
            // 알림 성공/실패와 무관하게 next_due_at을 전진하여 중복 알림 방지
            routine.advanceNextDue(now);
        }
    }
}
