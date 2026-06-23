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
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class RoutineScheduler {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private final RoutineMstRepository routineRepository;
    private final RoutinePetRlsRepository routinePetRepository;
    private final PetMstRepository petRepository;
    private final NotificationService notificationService;

    /**
     * 매 1분마다 오늘 알림을 보내야 할 루틴 스캔.
     * nextDueAt == 오늘(Seoul) AND alarmTime이 지남 AND 오늘 미발송 → 알림 전송.
     * nextDueAt은 절대 변경하지 않음.
     */
    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void processRoutineNotifications() {
        LocalDate today       = LocalDate.now(SEOUL);
        LocalTime currentTime = LocalTime.now(SEOUL);
        Instant   startOfToday = today.atStartOfDay(SEOUL).toInstant();

        List<RoutineMst> readyList = routineRepository.findReadyToNotify(today, currentTime, startOfToday);
        if (readyList.isEmpty()) return;

        log.debug("Sending notifications for {} routine(s)", readyList.size());

        Instant now = Instant.now();
        for (RoutineMst routine : readyList) {
            try {
                List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routine.getId());
                if (!petIds.isEmpty()) {
                    notificationService.createRoutineNotification(
                            routine.getUserId(),
                            petIds.get(0),
                            routine.getId(),
                            petIds.size(),
                            buildTitle(routine, petIds),
                            routine.getTitle()
                    );
                }
            } catch (Exception e) {
                log.warn("Notification failed for routine id={}: {}", routine.getId(), e.getMessage());
            }
            routine.markNotified(now);
        }
    }

    /**
     * 매일 Seoul 자정(00:00:01) 실행.
     * 예정일이 지난 미완료 루틴을 다음 주기 날짜로 전진.
     * (알람 시간이 아닌 날짜 기준으로만 처리)
     */
    @Scheduled(cron = "1 0 0 * * *", zone = "Asia/Seoul")
    @Transactional
    public void rollOverPastDueRoutines() {
        LocalDate today = LocalDate.now(SEOUL);
        List<RoutineMst> overdueList = routineRepository.findOverduePastDate(today);
        if (overdueList.isEmpty()) return;

        log.debug("Rolling over {} past-due routine(s)", overdueList.size());
        for (RoutineMst routine : overdueList) {
            routine.advanceDueDate();
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
