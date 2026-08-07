package io.bitpet.support;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * 통합 테스트 공통 베이스 — PostgreSQL·Redis 컨테이너를 <b>JVM당 한 번</b> 띄워 전 테스트가 공유한다.
 *
 * <p>⛔ {@code @Testcontainers} / {@code @Container} 를 붙이지 말 것. 그 조합은 컨테이너 수명을
 * <b>테스트 클래스 단위</b>로 관리해서, 첫 클래스가 끝나는 순간 static 컨테이너를 멈춰버린다.
 * 그러면 두 번째 클래스는 이미 죽은 컨테이너를 그대로 물고 들어가 전부
 * {@code CannotCreateTransactionException(ConnectException)} 으로 깨진다
 * (테스트 클래스가 하나뿐일 땐 드러나지 않는 함정이다).
 * 아래처럼 직접 start 하고 JVM 종료까지 살려두는 싱글턴 방식이 정답이다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public abstract class IntegrationTestBase {

    @ServiceConnection
    @SuppressWarnings("resource")
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>("postgres:16-alpine")
                    .withDatabaseName("bitpet")
                    .withUsername("bitpet")
                    .withPassword("bitpet");

    @SuppressWarnings("resource")
    static final GenericContainer<?> REDIS =
            new GenericContainer<>("redis:7-alpine").withExposedPorts(6379);

    static {
        POSTGRES.start();
        REDIS.start();
    }

    @DynamicPropertySource
    static void redisProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", REDIS::getHost);
        registry.add("spring.data.redis.port", () -> REDIS.getMappedPort(6379));
    }

    @Autowired
    protected MockMvc mockMvc;
}
