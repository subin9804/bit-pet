package io.bitpet.scheduler;

import io.bitpet.auth.dto.ChildCreateRequest;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.service.AuthService;
import io.bitpet.auth.service.GuardianService;
import io.bitpet.auth.dto.ChildResponse;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.notification.dto.NotificationLogResponse;
import io.bitpet.notification.service.NotificationService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 만 14세 자녀 계정의 보호자 연결 해제 + 보호자 알림 (V23, 2026-11-06).
 *
 * <p>배치의 기준일을 1년 뒤로 넘겨서 '만 13세 자녀가 14세가 된 날'을 만든다.
 */
class GuardianReleaseIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    @Autowired private GuardianReleaseScheduler scheduler;
    @Autowired private GuardianService guardianService;
    @Autowired private AuthService authService;
    @Autowired private NotificationService notificationService;
    @Autowired private UserMstRepository userRepository;

    @Test
    void child_turning_14_is_released_and_guardian_is_notified_once() {
        LocalDate today = LocalDate.now(SEOUL);
        Long guardian = signup();
        Long older = createChild(guardian, today.minusYears(13));   // 1년 뒤 14세
        Long younger = createChild(guardian, today.minusYears(10)); // 1년 뒤에도 11세

        LocalDate nextYear = today.plusYears(1);
        scheduler.run(nextYear);

        assertThat(userRepository.findById(older).orElseThrow().getGuardianReleasedAt()).isNotNull();
        // 동의 근거라 보호자 id 는 남는다
        assertThat(userRepository.findById(older).orElseThrow().getGuardianUserId()).isEqualTo(guardian);
        assertThat(userRepository.findById(younger).orElseThrow().getGuardianReleasedAt()).isNull();

        assertThat(notificationService.listNotifications(guardian))
                .extracting(NotificationLogResponse::title)
                .containsExactly("자녀 계정이 일반 계정으로 바뀌었어요");

        // 다음 날 다시 돌아도 알림이 또 가면 안 된다
        scheduler.run(nextYear.plusDays(1));
        assertThat(notificationService.listNotifications(guardian)).hasSize(1);
    }

    @Test
    void released_child_leaves_guardian_list_and_stops_blocking_withdrawal() {
        LocalDate today = LocalDate.now(SEOUL);
        Long guardian = signup();
        Long child = createChild(guardian, today.minusYears(13));

        // 해제 전: 목록에 있고, 보호자 탈퇴는 막힌다
        assertThat(guardianService.listChildren(guardian)).extracting(ChildResponse::id).containsExactly(child);
        assertThatThrownBy(() -> authService.withdraw(guardian, true)).isInstanceOf(BusinessException.class);

        scheduler.run(today.plusYears(1));

        assertThat(guardianService.listChildren(guardian)).isEmpty();
        // 해제된 계정은 더 이상 보호자가 지울 수 없다 — 본인 계정이다
        assertThatThrownBy(() -> guardianService.deleteChild(guardian, child))
                .isInstanceOf(BusinessException.class);
        authService.withdraw(guardian, true);
        assertThat(userRepository.findById(child)).isPresent();
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "grel" + n + "@example.com", "Passw0rd!23", "grelparent" + n, null,
                true, true, true, false, null)).id();
    }

    private Long createChild(Long guardian, LocalDate birthDate) {
        int n = SEQ.incrementAndGet();
        return guardianService.createChild(guardian, new ChildCreateRequest(
                "grelkid" + n + "@example.com", "Passw0rd!23", "grelkid" + n, null,
                birthDate, true, false)).id();
    }
}
