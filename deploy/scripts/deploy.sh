#!/usr/bin/env bash
#
# 앱 컨테이너 교체. GitHub Actions 가 SSH 로 호출하지만, 손으로도 그대로 쓸 수 있다.
#
#   ./scripts/deploy.sh ghcr.io/subin9804/tailog-app:<커밋SHA>
#
# 하는 일: DB 백업 → 이미지 pull → 교체 → 헬스체크 → 실패하면 직전 태그로 롤백.
#
# ⚠️ DB·Redis·Nginx 는 건드리지 않는다. 앱만 갈아끼운다.

set -euo pipefail

IMAGE_REF="${1:?사용법: deploy.sh <이미지:태그>}"
NEW_TAG="${IMAGE_REF##*:}"

cd "$(dirname "$0")/.."
COMPOSE="docker compose -f docker-compose.prod.yml --env-file .env.prod"

[ -f .env.prod ] || { echo "✗ .env.prod 가 없다. README 1번 참고"; exit 1; }

# ── 롤백 지점 기록 ───────────────────────────────────────────────────────────
# 지금 떠 있는 태그. 배포가 실패했을 때 되돌아갈 곳이다.
PREV_TAG="$(grep -E '^IMAGE_TAG=' .env.prod | cut -d= -f2- || true)"
echo "▸ 현재: ${PREV_TAG:-(없음)} → 새 버전: $NEW_TAG"

# ── 백업 ─────────────────────────────────────────────────────────────────────
# 마이그레이션이 먼저 돌기 때문에 백업은 반드시 pull 보다 앞이다.
# Flyway 가 DDL 을 적용한 뒤에 뜬 백업은 사고가 났을 때 되돌릴 지점이 되지 못한다.
if docker ps --format '{{.Names}}' | grep -q tailog-postgres; then
    echo "▸ DB 백업"
    ./scripts/backup-db.sh
else
    echo "▸ postgres 가 안 떠 있다 — 백업 생략 (최초 배포로 간주)"
fi

# ── 태그 교체 ────────────────────────────────────────────────────────────────
write_tag() {
    if grep -qE '^IMAGE_TAG=' .env.prod; then
        sed -i "s|^IMAGE_TAG=.*|IMAGE_TAG=$1|" .env.prod
    else
        printf '\nIMAGE_TAG=%s\n' "$1" >> .env.prod
    fi
}
write_tag "$NEW_TAG"

echo "▸ 이미지 받기"
$COMPOSE pull app

echo "▸ 교체"
$COMPOSE up -d app

# ── 헬스체크 ─────────────────────────────────────────────────────────────────
# Dockerfile 의 HEALTHCHECK 결과를 그대로 읽는다. 여기서 따로 curl 을 치면
# 판정 기준이 둘로 갈라져, 컨테이너는 healthy 인데 배포는 실패하는 일이 생긴다.
#
# start-period 90s + retries 5 라 최악의 경우 4분 가까이 걸린다. 240초를 준다.
echo -n "▸ 기동 대기"
CID=""
for _ in $(seq 1 120); do
    CID="$($COMPOSE ps -q app | head -n1)"
    [ -n "$CID" ] && break
    sleep 2
done

HEALTHY=false
for _ in $(seq 1 120); do
    STATUS="$(docker inspect -f '{{.State.Health.Status}}' "$CID" 2>/dev/null || echo starting)"
    if [ "$STATUS" = "healthy" ]; then HEALTHY=true; break; fi
    # 컨테이너가 죽어버린 경우엔 더 기다릴 이유가 없다
    RUNNING="$(docker inspect -f '{{.State.Running}}' "$CID" 2>/dev/null || echo false)"
    if [ "$RUNNING" != "true" ]; then break; fi
    echo -n "."
    sleep 2
done
echo

# ── 롤백 ─────────────────────────────────────────────────────────────────────
if [ "$HEALTHY" != true ]; then
    echo "✗ 새 버전이 healthy 가 되지 않았다. 마지막 로그:"
    $COMPOSE logs --tail 80 app || true

    if [ -n "$PREV_TAG" ]; then
        echo "▸ $PREV_TAG 로 롤백"
        write_tag "$PREV_TAG"
        $COMPOSE up -d app
        echo "✓ 롤백 완료 — 배포는 실패로 처리한다"
    else
        echo "✗ 되돌아갈 이전 태그가 없다 (최초 배포). 컨테이너를 그대로 두고 종료한다"
    fi
    exit 1
fi

# ── 정리 ─────────────────────────────────────────────────────────────────────
# 태그마다 이미지가 쌓여 20GB 디스크를 금방 채운다. 떠 있는 것만 남기고 지운다.
# ⚠️ -a 를 붙이지 않는다. 붙이면 롤백 대상인 직전 이미지까지 사라진다.
docker image prune -f >/dev/null 2>&1 || true

echo "✓ 배포 완료 — $NEW_TAG"
