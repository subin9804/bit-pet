package io.bitpet.common.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.io.InputStream;

/**
 * Firebase Admin SDK 초기화.
 *
 * <p>서비스 계정 키를 찾지 못하면 {@link FirebaseMessaging} 빈을 만들지 않는다.
 * {@code FcmSender}는 빈이 없으면 발송을 건너뛰므로 키 없이도 서버가 정상 기동한다.
 *
 * <p>키 탐색 순서:
 * <ol>
 *   <li>{@code bitpet.fcm.credentials-path} (파일 경로 또는 {@code classpath:} 접두사)</li>
 *   <li>환경변수 {@code GOOGLE_APPLICATION_CREDENTIALS} 기반 Application Default Credentials</li>
 * </ol>
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
public class FirebaseConfig {

    private static final String CLASSPATH_PREFIX = "classpath:";

    private final FcmProperties fcmProperties;

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        if (!fcmProperties.enabled()) {
            log.info("[FCM] bitpet.fcm.enabled=false — 푸시 발송 비활성화 (알림은 DB에만 기록)");
            return null;
        }

        GoogleCredentials credentials = loadCredentials();
        if (credentials == null) {
            log.warn("[FCM] 서비스 계정 자격증명을 찾지 못했습니다 — 푸시 발송 비활성화 "
                    + "(bitpet.fcm.credentials-path 또는 GOOGLE_APPLICATION_CREDENTIALS 설정 필요)");
            return null;
        }

        FirebaseOptions.Builder builder = FirebaseOptions.builder().setCredentials(credentials);
        if (fcmProperties.projectId() != null && !fcmProperties.projectId().isBlank()) {
            builder.setProjectId(fcmProperties.projectId());
        }

        FirebaseApp app = FirebaseApp.getApps().isEmpty()
                ? FirebaseApp.initializeApp(builder.build())
                : FirebaseApp.getInstance();

        log.info("[FCM] Firebase Admin SDK 초기화 완료 (projectId={})", app.getOptions().getProjectId());
        return FirebaseMessaging.getInstance(app);
    }

    private GoogleCredentials loadCredentials() {
        String path = fcmProperties.credentialsPath();

        if (path != null && !path.isBlank()) {
            Resource resource = path.startsWith(CLASSPATH_PREFIX)
                    ? new ClassPathResource(path.substring(CLASSPATH_PREFIX.length()))
                    : new FileSystemResource(path);

            if (!resource.exists()) {
                log.warn("[FCM] credentials-path 파일 없음: {}", path);
                return null;
            }
            try (InputStream in = resource.getInputStream()) {
                return GoogleCredentials.fromStream(in);
            } catch (IOException e) {
                log.warn("[FCM] 서비스 계정 키 읽기 실패: {} ({})", path, e.getMessage());
                return null;
            }
        }

        try {
            return GoogleCredentials.getApplicationDefault();
        } catch (IOException e) {
            return null;
        }
    }
}
