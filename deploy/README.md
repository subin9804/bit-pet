# tailog 배포 (Lightsail 단일 인스턴스)

`tailog.me` → **15.165.103.232** (DNS 설정 완료, `www` 포함)

앱·DB·Redis·Nginx를 한 인스턴스에 도커로 올린다. 관리형 DB를 쓰지 않는 대신
**백업(`scripts/backup-db.sh`) + Lightsail 스냅샷**을 반드시 켠다.

---

## 0. 인스턴스 준비 (최초 1회)

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2 git
sudo usermod -aG docker $USER   # 재로그인 필요
```

**스왑 추가 — 2GB 인스턴스라면 필수다.** 빌드는 GitHub Actions 로 옮겼지만
postgres·redis·nginx·app 이 한 인스턴스에 같이 살아서 여유가 없다. 스왑이 없으면
순간 부하에 OOM Killer 가 컨테이너 하나를 골라 죽인다 (보통 제일 큰 postgres).

```bash
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**방화벽** — Lightsail 콘솔 > 네트워킹에서 **80, 443만** 연다.
5432(DB)·6379(Redis)는 절대 열지 않는다. compose 가 호스트에 노출하지 않으므로
컨테이너끼리만 통신한다.

---

## 1. 코드와 시크릿 배치

```bash
git clone https://github.com/subin9804/bit-pet.git
cd bit-pet/deploy

cp .env.prod.example .env.prod
chmod 600 .env.prod
nano .env.prod            # 빈 값 전부 채우기 (생성 명령은 파일 주석 참고)

mkdir -p secrets backups
# Firebase 서비스 계정 키를 로컬 PC에서 복사
#   scp -i key.pem bitpet_server/secrets/firebase-service-account.json ubuntu@15.165.103.232:~/bit-pet/deploy/secrets/
```

> ⚠️ `google-services.json` 과 `firebase_options.dart` 는 앱 빌드용이라 서버에는 필요 없다.
> 서버가 필요한 건 `firebase-service-account.json` 하나뿐이다.

---

## 2. 최초 인증서 발급

인증서가 없는 상태로는 `tailog.conf` 의 443 블록 때문에 nginx 가 기동조차 안 된다.
그래서 80만 여는 임시 설정으로 한 번 띄우고 발급받는다.

```bash
cd nginx/conf.d
mv tailog.conf tailog.conf.off
mv bootstrap.conf.disabled bootstrap.conf
cd ../..

# ⚠️ --no-deps 필수. nginx 는 depends_on: app 이라 이게 없으면 compose 가 app 도 같이
#    띄우려 든다. 이 시점엔 GHCR 에 이미지가 아직 없어서 pull 이 실패하고 nginx 도 못 뜬다.
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --no-deps nginx
curl http://tailog.me/          # bootstrap 이 떠야 함

# ⚠️ --entrypoint certbot 필수. compose 의 certbot 서비스는 entrypoint 가 "renew 무한루프"라
#    그냥 run 하면 certonly 인자가 sh -c 의 $0/$1 로 먹혀 무시되고 갱신 루프만 돈다
#    (발급이 안 되는데 에러도 안 난다). 이미지 기본 entrypoint 로 되돌려야 발급이 실행된다.
docker compose -f docker-compose.prod.yml --env-file .env.prod run --rm \
  --entrypoint certbot certbot \
  certonly --webroot -w /var/www/certbot \
  -d tailog.me -d www.tailog.me \
  --email su9804@gmail.com --agree-tos --no-eff-email

cd nginx/conf.d
mv bootstrap.conf bootstrap.conf.disabled
mv tailog.conf.off tailog.conf
cd ../..

# ⚠️ 설정 파일은 bind mount 라 파일만 바꿔서는 안 바뀐다. nginx 는 아직 bootstrap 을
#    메모리에 들고 있으므로 명시적으로 재시작해야 443 이 열린다.
#    (3번의 up -d 는 nginx 를 재생성하지 않는다 — compose 가 보기에 달라진 게 없다)
docker compose -f docker-compose.prod.yml --env-file .env.prod restart nginx
```

앱이 아직 없어도 nginx 는 정상 기동한다 — `tailog.conf` 가 upstream 을 변수로 잡아
기동 시점에 해석하지 않기 때문이다(무중단 배포 대비로 넣어둔 구조).

> 💡 **`--dry-run` 을 먼저 돌려라.** 위 `certonly` 명령 맨 뒤에 `--dry-run` 을 붙여 성공을
> 확인한 다음, 빼고 다시 실행한다. Let's Encrypt 는 **주당 발급 횟수 제한**이 있어
> 설정을 고쳐가며 실제 발급을 반복하면 일주일간 막힌다.
>
> 발급 확인: `docker compose -f docker-compose.prod.yml --env-file .env.prod run --rm --entrypoint certbot certbot certificates`

---

## 3. 전체 기동

앱 이미지는 **서버에서 빌드하지 않는다.** GitHub Actions 가 만들어 GHCR 에 올린 것을 받아 쓴다
(아래 [CI/CD](#cicd-자동-배포) 참고). 그래서 최초 기동 전에 워크플로가 한 번은 돌아 있어야 한다.

```bash
# GHCR 은 비공개 패키지다. 최초 1회만 로그인해 두면 아래 pull 이 통과한다.
#   PAT: github.com/settings/tokens (classic) > read:packages 만 체크
echo <PAT> | docker login ghcr.io -u subin9804 --password-stdin

# .env.prod 의 IMAGE_TAG 에 배포할 커밋 SHA 를 적는다 (Actions 실행 로그에서 확인)
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
docker compose -f docker-compose.prod.yml --env-file .env.prod logs -f app
```

`Started BitPetApplication` 확인 후:

```bash
curl https://tailog.me/api/v1/memo-tags
```

Flyway 마이그레이션(V1~V55)은 앱 첫 기동 때 자동 실행된다.

---

## 4. 백업 크론

```bash
chmod +x scripts/backup-db.sh
crontab -e
# 0 4 * * * /home/ubuntu/bit-pet/deploy/scripts/backup-db.sh >> /home/ubuntu/backup.log 2>&1
```

Lightsail 콘솔에서 **자동 스냅샷**도 함께 켠다.

---

## 5. 앱 재빌드 (서버가 https 로 뜬 뒤)

```bash
cd bitpet_app
flutter build appbundle --dart-define=API_BASE_URL=https://tailog.me/api/v1
```

⚠️ `--dart-define` 을 빠뜨리면 앱이 `localhost` 를 보고 모든 요청이 실패한다.
증상이 "네트워크 에러"라 원인이 드러나지 않는다.

---

## 6. Play 앱 서명 지문 추가 (AAB 업로드 후)

Play 는 업로드한 AAB 를 **자기 키로 재서명**한다. 그래서 최종 앱의 지문이 업로드 키와 다르고,
`assetlinks.json` 에 **둘 다** 들어가야 NFC 딥링크가 앱으로 열린다.

1. Play Console > 설정 > 앱 서명 > **앱 서명 키 인증서 SHA-256** 복사
2. `.env.prod` 의 `BITPET_ANDROID_SHA256` 에 콤마로 이어붙이기
3. `docker compose -f docker-compose.prod.yml --env-file .env.prod up -d app`
4. 검증: `curl https://tailog.me/.well-known/assetlinks.json` — 지문 2개가 보여야 함

서버 설정만 바뀌는 것이라 **앱 재배포는 필요 없다.**

---

## CI/CD (자동 배포)

`master` 에 `bitpet_server/**` 또는 `deploy/**` 가 푸시되면 자동으로 배포된다.
워크플로: `.github/workflows/deploy.yml`

```
push → ① test (Gradle + Testcontainers)
     → ② build (docker buildx → ghcr.io/subin9804/tailog-app:<커밋SHA>)
     → ③ deploy (SSH → deploy/scripts/deploy.sh)
```

`deploy.sh` 는 **DB 백업 → pull → 교체 → 헬스체크 → 실패 시 직전 태그로 자동 롤백** 순서다.
백업이 pull 보다 앞인 이유: 새 컨테이너가 뜨는 순간 Flyway 가 DDL 을 적용해 버리므로,
그 뒤에 뜬 백업은 되돌릴 지점이 되지 못한다.

### 등록해야 하는 GitHub Secret

| 이름 | 값 |
|---|---|
| `DEPLOY_SSH_KEY` | Lightsail 접속 개인키 **전문** (`-----BEGIN ...` 줄 포함) |

`GITHUB_TOKEN` 은 Actions 가 자동으로 넣어준다. 서버의 GHCR 로그인도 이 임시 토큰으로
그때그때 하고 끝나면 `docker logout` 한다 — **서버에 장기 PAT 를 심어두지 않기 위한 것**이다.
(사람이 손으로 `docker compose pull` 할 때만 위 3번의 read:packages PAT 가 필요하다.)

### 최초 1회 설정

1. **Secret 등록** — 레포 > Settings > Secrets and variables > Actions > `DEPLOY_SSH_KEY`
2. **서버 준비** — `~/bit-pet` 이 `origin/master` 를 추적하는 clone 이어야 한다
   (`deploy.sh` 가 `git fetch && checkout -B master origin/master` 를 한다.
   ⚠️ 서버에서 파일을 직접 고쳤다면 그 변경은 덮어써진다)
3. **패키지 연결** — 첫 푸시 후 GHCR 패키지 페이지에서 레포와 연결되었는지 확인.
   패키지는 **비공개로 둔다** — 레포가 public 이라 소스는 어차피 공개지만,
   이미지까지 열면 우리 서버가 어떤 버전으로 도는지가 그대로 노출된다

### 롤백

```bash
cd ~/bit-pet/deploy
nano .env.prod                     # IMAGE_TAG 를 되돌릴 커밋 SHA 로
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d app
```

배포 실패는 `deploy.sh` 가 알아서 되돌리므로, 이 수동 절차는 **떴는데 동작이 이상할 때** 쓴다.

### 손으로 배포하기

```bash
cd ~/bit-pet/deploy && git -C .. pull
./scripts/deploy.sh ghcr.io/subin9804/tailog-app:<커밋SHA>
```

---

## 무중단 배포 (아직 안 함 — 준비만 되어 있음)

현재는 앱 컨테이너를 **멈췄다 새로 띄운다.** 기동에 30초~1분 걸리므로 그동안 502 다.
사용자가 붙기 전에는 이걸로 충분하고, 무중단으로 넘어갈 때 **구조를 뜯어고칠 필요는 없게** 해뒀다:

| 이미 해결됨 | 어디 |
|---|---|
| nginx 가 매 요청 DNS 재조회 (컨테이너 IP 가 바뀌어도 502 안 남) | `nginx/conf.d/tailog.conf` — `resolver 127.0.0.11` + `set $upstream_app` |
| `container_name` 없음 (있으면 `--scale` 로 2개를 못 띄운다) | `docker-compose.prod.yml` app 서비스 |
| 이미지 태그가 불변 (커밋 SHA) — 두 버전을 동시에 지정할 수 있다 | `IMAGE_TAG` |
| 컨테이너 자체 HEALTHCHECK (새 버전이 준비됐는지 판정) | `bitpet_server/Dockerfile` |

전환할 때 할 일은 `deploy.sh` 의 교체 구간을 `up -d --scale app=2` → 새 컨테이너 healthy 대기
→ 옛 컨테이너 제거로 바꾸는 것뿐이다.

🚨 **단, 그때부터 Flyway 마이그레이션은 반드시 expand/contract 여야 한다.**
교체가 겹치는 동안 **구버전과 신버전 앱이 같은 스키마에 동시에 붙어 있기 때문**이다.
컬럼을 지우거나 이름을 바꾸는 마이그레이션을 그대로 올리면, 아직 살아 있는 구버전이
없는 컬럼을 조회하다 터진다. 두 단계로 나눈다:

1. **expand** — 새 컬럼을 nullable 로 추가만 한다 (구버전은 모르는 채로 잘 돈다)
2. 두 버전 모두 신버전이 된 뒤, **contract** — 다음 배포에서 옛 컬럼을 지운다

---

## 자주 막히는 곳

| 증상 | 원인 |
|---|---|
| nginx 가 안 뜸 | 인증서 없이 443 블록 로드. 2번 순서대로 |
| 앱이 "네트워크 에러" | `--dart-define` 누락, 또는 앱이 아직 localhost 빌드 |
| 사진 업로드 실패 | `client_max_body_size` 초과, 또는 S3 자격증명/버킷 오류 |
| NFC 태그가 브라우저로 열림 | `assetlinks.json` 에 Play 서명 지문 누락 (6번) |
| 로그인만 실패 | Redis 비밀번호 불일치 (`REDIS_PASSWORD`) |
| 서버가 이따금 멈춤 | 스왑 미설정 (0번) |
| 배포 시 `pull access denied` | GHCR 로그인 만료. 워크플로가 아니라 손으로 배포하는 중이라면 PAT 재로그인 (3번) |
| 배포가 롤백됨 | 새 이미지가 healthy 가 못 됨. `docker compose logs app` — 대개 Flyway 실패 아니면 `.env.prod` 누락 |
| Actions 가 `test` 에서 실패 | 배포 전 단계다. 서버 문제가 아니라 코드 문제 — `cd bitpet_server && ./gradlew test` 로 로컬에서 먼저 재현할 것 |
| certbot 이 아무 반응 없이 도는 중 | `--entrypoint certbot` 누락. compose 의 entrypoint(갱신 무한루프)가 인자를 먹어버린 것 (2번) |
| `up -d nginx` 가 이미지 pull 실패로 죽음 | `--no-deps` 누락 — `depends_on: app` 때문에 아직 없는 앱 이미지를 받으러 간다 (2번) |
| 인증서를 받았는데 여전히 `bootstrap` 응답 | nginx 재시작 누락. 설정은 bind mount 라 파일만 바꿔선 안 바뀐다 (2번) |
