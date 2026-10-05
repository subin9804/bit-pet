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
            List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routine.getId());

            // 개체가 없으면 보낼 알림이 없다 — markNotified 도 찍지 않고 넘어간다.
            // 찍어버리면 '오늘 보냈음'이 되어 그날 다시 스캔되지 않으므로, 오늘 안에
            // 개체를 연결해도 알림이 오지 않는다 (RoutineMst 빌더가 active=true 를
            // 무조건 세팅하므로 0마리 루틴도 이 목록에 들어온다).
            if (petIds.isEmpty()) {
                log.debug("Routine id={} has no pets — skipping without marking notified", routine.getId());
                continue;
            }

            try {
                notificationService.createRoutineNotification(
                        routine.getUserId(),
                        petIds.get(0),
                        routine.getId(),
                        petIds.size(),
                        buildTitle(routine, petIds),
                        routine.getTitle()
                );
            } catch (Exception e) {
                log.warn("Notification failed for routine id={}: {}", routine.getId(), e.getMessage());
            }
            // 실패해도 찍는다 — 안 찍으면 같은 루틴을 1분마다 하루 종일 재시도한다.
            // 발송 실패 자체는 notification_log_dtl 의 status=FAILED 로 남는다.
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
