-- ════════════════════════════════════════════════════════════════
-- 삭제된 개체를 가리키는 알(laying_hatch_dtl) 연결 정리
--
-- 개체 삭제는 소프트 삭제(pet_mst.deleted_at)라서 FK 의 ON DELETE SET NULL 도,
-- 물리 삭제 경로(PetPurgeRepository)의 링크 해제도 돌지 않았다. 그래서 알 칸이
-- '등록됨'으로 보이는데 눌러도 없는 개체로 가고, 등록된 알은 상태 순환에서 빠지므로
-- (HATCH_ALREADY_REGISTERED) 되돌릴 수조차 없는 유령 상태가 남았다.
--
-- 앞으로 생기는 건 LayingMaintenanceService.onPetDeleted 가 끊는다. 이 파일은
-- 그 전에 이미 생긴 행을 정리한다.
--
-- ⚠️ status 는 건드리지 않는다 — 부화는 실제로 일어난 일이고 개체를 지운 것과 별개다.
--    PENDING 으로 되돌리면 "부화한 적 없는 알"이 되어 기록이 거짓이 된다.
--    연결이 끊기면 알 칸을 다시 눌러 순환시킬 수 있으므로 판단은 사용자에게 남긴다.
-- ════════════════════════════════════════════════════════════════

UPDATE laying_hatch_dtl h
   SET hatched_pet_id = NULL,
       updated_at     = now()
 WHERE h.hatched_pet_id IS NOT NULL
   AND NOT EXISTS (
         SELECT 1 FROM pet_mst p
          WHERE p.id = h.hatched_pet_id
            AND p.deleted_at IS NULL
       );
