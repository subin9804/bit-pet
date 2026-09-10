#!/usr/bin/env bash
# PostgreSQL 백업 — 컨테이너 DB의 유일한 안전망이다.
#
# 크론 등록 (매일 04:00 KST):
#   crontab -e
#   0 4 * * * /home/ubuntu/bit-pet/deploy/scripts/backup-db.sh >> /home/ubuntu/backup.log 2>&1
#
# ⚠️ 이 백업은 같은 인스턴스 디스크에 쌓인다. 인스턴스가 통째로 날아가면 백업도 같이 날아간다.
#    Lightsail 스냅샷(주 1회 자동)을 반드시 함께 켤 것. 둘은 대체재가 아니다 —
#    스냅샷은 "인스턴스 복구", 이 덤프는 "실수로 지운 데이터 되살리기"용이다.

set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DEPLOY_DIR"

# shellcheck disable=SC1091
set -a; source .env.prod; set +a

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="/backups/bitpet-${STAMP}.sql.gz"

mkdir -p ./backups

docker compose -f docker-compose.prod.yml --env-file .env.prod exec -T postgres \
  sh -c "pg_dump -U '${POSTGRES_USER}' -d '${POSTGRES_DB}' | gzip -9 > '${OUT}'"

echo "[$(date '+%F %T')] 백업 완료: ${OUT}"

# 14일 지난 덤프 정리. 무한히 쌓아두면 디스크가 차서 DB가 쓰기 실패한다.
find ./backups -name 'bitpet-*.sql.gz' -mtime +14 -delete

echo "[$(date '+%F %T')] 보관본 $(find ./backups -name 'bitpet-*.sql.gz' | wc -l)개"
