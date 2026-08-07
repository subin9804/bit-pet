package io.bitpet.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * {@code @EnableAsync} 는 S3 삭제 큐 소진용이다 — 커밋 직후 후처리를 요청 스레드에서 돌리면
 * 탈퇴 응답이 S3 호출 수백 건만큼 늦어진다.
 */
@Configuration
@EnableScheduling
@EnableAsync
public class SchedulerConfig {}
