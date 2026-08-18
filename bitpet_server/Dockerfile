# syntax=docker/dockerfile:1

# ──────────────────────────────────────────────────────────────
# 1단계: 빌드 (JDK 필요)
# ──────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src

# 의존성 정의만 먼저 복사한다. 소스만 고쳤을 때 의존성 다운로드 레이어를
# 캐시에서 재사용하려는 것 — 이게 없으면 코드 한 줄 고칠 때마다 전부 다시 받는다.
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle.kts settings.gradle.kts ./
RUN chmod +x gradlew && ./gradlew --no-daemon dependencies > /dev/null 2>&1 || true

COPY src ./src
# 테스트는 Testcontainers(도커 인 도커)를 요구하므로 이미지 빌드에서는 제외한다.
RUN ./gradlew --no-daemon clean bootJar -x test

# ──────────────────────────────────────────────────────────────
# 2단계: 실행 (JRE만 — 이미지 크기 절감)
# ──────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S app && adduser -S app -G app
USER app

COPY --from=build --chown=app:app /src/build/libs/*.jar app.jar

# 컨테이너 메모리 한도를 인식해 힙을 잡게 한다. 고정 -Xmx 를 쓰지 않는 이유는
# 인스턴스를 키웠을 때 설정을 같이 안 고치면 늘어난 메모리를 못 쓰기 때문.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=65 -XX:+UseSerialGC -Duser.timezone=Asia/Seoul"
ENV SPRING_PROFILES_ACTIVE=prod

EXPOSE 8080

# 인증이 필요 없는 엔드포인트로 확인한다. /actuator/health 는 DOWN 으로 뜬 이력이 있어 쓰지 않는다.
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=5 \
  CMD wget -qO- http://localhost:8080/api/v1/memo-tags > /dev/null || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
