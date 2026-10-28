package io.bitpet.auth;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.notification.domain.DevicePlatform;
import io.bitpet.notification.dto.DeviceTokenRegisterRequest;
import io.bitpet.notification.service.DeviceTokenService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 탈퇴하면 개인정보가 실제로 지워지는가 — 처리방침의 "지체 없이 삭제" 약속.
 *
 * <p>user_mst 는 @SQLRestriction 으로 탈퇴 행이 안 보이므로 JdbcTemplate 로 직접 본다.
 */
class WithdrawalPersonalDataIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private DeviceTokenService deviceTokenService;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void 탈퇴하면_이메일_닉네임_비밀번호_푸시토큰이_지워진다() {
        int n = SEQ.incrementAndGet();
        String email = "scrub" + n + "@example.com";
        String nickname = "scrub" + n;
        Long userId = authService.signup(new SignupRequest(
                email, "Passw0rd!23", nickname, null, true, true, true, false)).id();
        deviceTokenService.register(userId,
                new DeviceTokenRegisterRequest("token-scrub-" + n, DevicePlatform.ANDROID, null));

        authService.withdraw(userId, true);

        Map<String, Object> row = jdbc.queryForMap(
                "SELECT email, name, password_hash, profile_image_url, birth_date, share_code, deleted_at"
                        + " FROM user_mst WHERE id = ?", userId);
        assertThat(row.get("deleted_at")).isNotNull();
        assertThat(row.get("email")).isEqualTo("deleted-" + userId + "@deleted.invalid");
        assertThat(row.get("name")).isEqualTo("deleted-" + userId);
        assertThat(row.get("password_hash")).isEqualTo("");
        assertThat(row.get("profile_image_url")).isNull();
        assertThat(row.get("birth_date")).isNull();
        assertThat(row.get("share_code")).isNull();
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM device_token_rls WHERE user_id = ?", Integer.class, userId)).isZero();
    }

    @Test
    void 탈퇴한_이메일과_닉네임으로_다시_가입할_수_있다() {
        int n = SEQ.incrementAndGet();
        String email = "rejoin" + n + "@example.com";
        String nickname = "rejoin" + n;
        Long first = authService.signup(new SignupRequest(
                email, "Passw0rd!23", nickname, null, true, true, true, false)).id();
        authService.withdraw(first, true);

        Long second = authService.signup(new SignupRequest(
                email, "Passw0rd!23", nickname, null, true, true, true, false)).id();

        assertThat(second).isNotEqualTo(first);
    }
}
