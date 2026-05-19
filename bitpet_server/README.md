# Bit-Pet Backend

Bit-Pet 크로스플랫폼 앱의 백엔드 서버.

## 스택

| 영역 | 기술 |
|---|---|
| 언어 | Java 21 (Gradle Toolchain — 시스템에 미설치되어 있어도 자동 다운로드) |
| 프레임워크 | Spring Boot 3.5.14 |
| 빌드 도구 | Gradle 8.14 (Kotlin DSL) |
| 데이터베이스 | PostgreSQL 16 |
| 캐시 / 토큰 저장 | Redis 7 |
| 인증 | JWT (jjwt 0.12) + Spring Security + (이후) OAuth2 |
| API 문서 | springdoc-openapi 2.7 (Swagger UI) |
| 운영 인프라 | Docker Compose |

## 디렉토리 구조

```
src/main/java/io/bitpet
├── BitPetApplication.java            # 엔트리포인트
├── common/
│   ├── entity/BaseTimeEntity.java    # createdAt / updatedAt 자동 감사
│   ├── response/ApiResponse.java     # { success, data, error, timestamp } 표준 응답
│   ├── exception/                    # ErrorCode, BusinessException, GlobalExceptionHandler
│   └── config/                       # Security/Swagger/Redis + SecurityProperties
├── auth/
│   ├── domain/                       # User, Role, AuthProvider
│   ├── jwt/                          # JwtProperties, JwtTokenProvider, JwtAuthenticationFilter, RefreshTokenStore, AuthPrincipal
│   ├── repository/UserRepository.java
│   ├── service/AuthService.java
│   ├── controller/AuthController.java
│   └── dto/                          # Signup/Login/Refresh/Token/User
└── pet/
    ├── domain/                       # Pet, PetSpecies, PetGender
    ├── repository/PetRepository.java
    ├── service/                      # SerialNumberGenerator + SerialNumberProperties + PetService
    ├── controller/PetController.java
    └── dto/                          # PetCreate/Update/Response
```

## 사전 준비

1. **Docker Desktop** 설치 (Windows)
   - https://www.docker.com/products/docker-desktop/
   - 설치 후 한 번 실행해서 엔진이 켜졌는지 확인.
2. **JDK는 별도 설치 불필요**
   - `build.gradle.kts`의 Gradle Toolchain 설정으로 Java 21을 Gradle이 자동 다운로드.
   - 시스템에 깔린 JDK 17은 그대로 두어도 됩니다.
3. **IntelliJ 설정** (권장)
   - File → Settings → Build, Execution, Deployment → Build Tools → Gradle
   - "Build and run using" → **Gradle**
   - "Gradle JVM" → **Download JDK 21 (Temurin/Adoptium 권장)** 또는 "Use Project SDK"

## 실행 순서

### 1) 인프라(Postgres + Redis) 띄우기

```powershell
cd C:\Users\subin\IdeaProjects\Bit-Pet
docker compose up -d
```

상태 확인:

```powershell
docker compose ps
docker compose logs -f postgres
docker compose logs -f redis
```

내릴 때:

```powershell
docker compose down            # 컨테이너만 정리 (데이터 유지)
docker compose down -v         # 데이터까지 삭제
```

### 2) 애플리케이션 실행 (local 프로파일)

IntelliJ에서 `BitPetApplication.main()` 실행. 또는 CLI:

```powershell
.\gradlew bootRun
```

기본 활성 프로파일은 `local` (Postgres `localhost:5432`, Redis `localhost:6379`).

### 3) 동작 확인

- Swagger UI: http://localhost:8080/swagger-ui.html
- Health check: http://localhost:8080/actuator/health
- API 베이스: `/api/v1`

## API 개요

| 메서드 | 경로 | 인증 | 설명 |
|---|---|---|---|
| POST | `/api/v1/auth/signup` | ✕ | 이메일/비밀번호 회원가입 |
| POST | `/api/v1/auth/login` | ✕ | 로그인 → access + refresh |
| POST | `/api/v1/auth/refresh` | ✕ | refresh로 access 재발급 (rotation) |
| POST | `/api/v1/auth/logout` | ✓ | refresh 무효화 |
| POST | `/api/v1/pets` | ✓ | 개체 등록 (일련번호 자동 발급) |
| GET | `/api/v1/pets` | ✓ | 내 개체 목록 |
| GET | `/api/v1/pets/{petId}` | ✓ | 단건 조회 |
| PATCH | `/api/v1/pets/{petId}` | ✓ | 부분 수정 |
| DELETE | `/api/v1/pets/{petId}` | ✓ | 삭제 |

인증 필요 엔드포인트는 헤더에 `Authorization: Bearer {accessToken}` 첨부.

## 핵심 도메인 규칙

### 개체 일련번호 (`SerialNumberGenerator`)

- **풀:** 32자 (`23456789ABCDEFGHJKLMNPQRSTUVWXYZ` — `0/O/I/1` 제외)
- **초기 길이:** 6자리 (총 32^6 = 약 10억 7천만 가지)
- **확장 규칙:** 등록된 개체 수가 현재 길이의 80% 이상이 되면 다음 발급부터 7자리, 그 다음 8자리…
- **충돌 처리:** 같은 길이에서 32회 시도 후에도 충돌이 계속되면 길이 +1로 강제 확장.
- 설정은 `application.yml`의 `bitpet.serial-number.*` 에서 변경.

### JWT

- **Access**: HS256, 30분, claims: `sub=userId, email, role, type=access`
- **Refresh**: HS256, 14일, claims: `sub=userId, type=refresh` — Redis (`bitpet:refresh:{userId}`)에 저장
- 비밀키는 32바이트 이상이어야 함 (HS256 요구사항). prod에서는 `BITPET_JWT_SECRET` 환경변수로 주입.

## 프로파일

| 파일 | 용도 |
|---|---|
| `application.yml` | 모든 프로파일 공통 (서버 포트, Jackson, Swagger, JWT 만료, CORS 등) |
| `application-local.yml` | 로컬 개발 — Docker Compose로 띄운 Postgres/Redis 연결, `ddl-auto=update`, SQL 로깅 ON |
| `application-prod.yml` | 운영 — 모든 값 환경변수, `ddl-auto=validate`, SQL 로깅 OFF |

활성 프로파일은 `SPRING_PROFILES_ACTIVE` 환경변수로 변경 (기본 `local`).

## 운영(prod) 환경변수

```
SPRING_PROFILES_ACTIVE=prod
BITPET_DB_URL=jdbc:postgresql://<host>:5432/bitpet
BITPET_DB_USERNAME=bitpet
BITPET_DB_PASSWORD=<secret>
BITPET_REDIS_HOST=<host>
BITPET_REDIS_PORT=6379
BITPET_REDIS_PASSWORD=<secret>     # 비번 없는 경우 빈 값
BITPET_JWT_SECRET=<32+ bytes ASCII>
BITPET_CORS_ORIGINS=https://app.example.com,https://admin.example.com
```

## 개발 명령어

```powershell
.\gradlew compileJava       # 컴파일만
.\gradlew bootRun           # 앱 실행
.\gradlew test              # 테스트
.\gradlew bootJar           # 실행 가능한 jar 빌드 → build/libs/
```

## 향후 작업 (계획)

- OAuth2 (Google / Kakao / Naver) 로그인 — `spring-boot-starter-oauth2-client` 의존성은 이미 포함, 프로파일별 클라이언트 키만 추가하면 됨
- DB 마이그레이션 도구 도입 (Flyway 권장)
- Testcontainers 기반 통합 테스트
- 커뮤니티/피드 도메인
- 오프라인 동기화 (Local-First) 지원
