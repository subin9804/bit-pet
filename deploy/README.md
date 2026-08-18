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

**스왑 추가 — 2GB 인스턴스라면 필수다.** Gradle 빌드가 메모리를 크게 먹어서
스왑 없이 `docker compose build` 를 돌리면 OOM 으로 죽는다.

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

docker compose -f docker-compose.prod.yml --env-file .env.prod up -d nginx
curl http://tailog.me/          # bootstrap 이 떠야 함

docker compose -f docker-compose.prod.yml --env-file .env.prod run --rm certbot \
  certonly --webroot -w /var/www/certbot \
  -d tailog.me -d www.tailog.me \
  --email su9804@gmail.com --agree-tos --no-eff-email

cd nginx/conf.d
mv bootstrap.conf bootstrap.conf.disabled
mv tailog.conf.off tailog.conf
cd ../..
```

> 💡 실패하면 `--dry-run` 을 붙여 먼저 시험한다. Let's Encrypt 는 **주당 발급 횟수 제한**이 있어
> 설정을 고쳐가며 실제 발급을 반복하면 일주일간 막힌다.

---

## 3. 전체 기동

```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
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

## 갱신 배포 (평상시)

```bash
cd ~/bit-pet && git pull
cd deploy
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build app
```

DB·Redis·Nginx 는 그대로 두고 app 컨테이너만 갈아끼운다.

---

## 자주 막히는 곳

| 증상 | 원인 |
|---|---|
| nginx 가 안 뜸 | 인증서 없이 443 블록 로드. 2번 순서대로 |
| 앱이 "네트워크 에러" | `--dart-define` 누락, 또는 앱이 아직 localhost 빌드 |
| 사진 업로드 실패 | `client_max_body_size` 초과, 또는 S3 자격증명/버킷 오류 |
| NFC 태그가 브라우저로 열림 | `assetlinks.json` 에 Play 서명 지문 누락 (6번) |
| 로그인만 실패 | Redis 비밀번호 불일치 (`REDIS_PASSWORD`) |
| 빌드 중 서버가 멈춤 | 스왑 미설정 (0번) |
