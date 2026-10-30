package io.bitpet.scheduler;

import io.bitpet.pet.repository.MorphCdRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 안 쓰는 사용자 정의 모프 정리 배치.
 *
 * <p>개체에서 모프를 빼거나 개체가 퍼지돼도 사용자 정의 모프 행은 남는다 — 그대로 두면
 * 그 사람의 모프 목록에 아무도 안 쓰는 이름이 계속 쌓인다. 연결을 끊는 경로(모프 수정·종 변경·
 * 개체 퍼지·탈퇴)가 여럿이라 각 경로에서 지우는 대신 여기 한 곳에서 몰아 지운다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MorphCleanupScheduler {

    private final MorphCdRepository morphRepository;

    /** 매일 Seoul 03:20 — 03:10 고아 개체 퍼지 뒤에 돌아야 그 개체들이 쓰던 모프까지 함께 지워진다 */
    @Scheduled(cron = "0 20 3 * * *", zone = "Asia/Seoul")
    public void deleteUnusedUserDefinedMorphs() {
        int deleted = morphRepository.deleteUnusedUserDefined();
        if (deleted > 0) {
            log.info("Morph cleanup: {} unused user-defined morph(s) deleted", deleted);
        }
    }
}
