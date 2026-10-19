package io.bitpet.record.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.record.dto.RecordBulkRequest.Item;
import io.bitpet.record.laying.service.LayingService;
import io.bitpet.record.mating.service.MatingService;
import io.bitpet.record.memo.service.MemoService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * 홈 캘린더 날짜 시트의 일괄 삭제 · 일괄 날짜 변경.
 *
 * <p>날짜를 잘못 고른 채 여러 마리를 한꺼번에 적으면, 전에는 개체마다 기록 화면에 들어가
 * 하나씩 고쳐야 했다 (2026-10-19 사용자 요청). 그 날짜의 시트에서 여러 종류·여러 개체를
 * 골라 한 번에 처리한다.
 *
 * <p>한 건씩 처리하는 로직은 <b>각 종류의 서비스에 그대로 맡긴다</b> — 권한 확인과 삭제 시
 * 딸린 행 정리(메모 태그, 산란의 알 칸 등)가 거기 있어서, 여기서 다시 짜면 어긋난다.
 * 전체가 한 트랜잭션이다: 하나라도 권한이 없거나 없는 기록이면 아무것도 바뀌지 않는다.
 */
@Service
@RequiredArgsConstructor
public class RecordBulkService {

    private final RecordService recordService;
    private final MemoService memoService;
    private final MatingService matingService;
    private final LayingService layingService;

    @Transactional
    public int delete(Long userId, List<Item> items) {
        List<Item> distinct = items.stream().distinct().toList();
        for (Item it : distinct) {
            switch (type(it)) {
                case "FEEDING"  -> recordService.deleteFeeding(userId, it.id());
                case "WEIGHT"   -> recordService.deleteWeight(userId, it.id());
                case "CLEANING" -> recordService.deleteCleaning(userId, it.id());
                case "MEMO"     -> memoService.deleteMemo(it.id(), userId);
                case "MATING"   -> matingService.deleteMating(it.id(), userId);
                case "LAYING"   -> layingService.deleteLaying(it.id(), userId);
                default         -> throw new BusinessException(ErrorCode.INVALID_INPUT);
            }
        }
        return distinct.size();
    }

    @Transactional
    public int move(Long userId, List<Item> items, LocalDate date) {
        List<Item> distinct = items.stream().distinct().toList();
        for (Item it : distinct) {
            switch (type(it)) {
                case "FEEDING"  -> recordService.moveFeeding(userId, it.id(), date);
                case "WEIGHT"   -> recordService.moveWeight(userId, it.id(), date);
                case "CLEANING" -> recordService.moveCleaning(userId, it.id(), date);
                case "MEMO"     -> memoService.moveMemo(it.id(), userId, date);
                case "MATING"   -> matingService.moveMating(it.id(), userId, date);
                case "LAYING"   -> layingService.moveLaying(it.id(), userId, date);
                default         -> throw new BusinessException(ErrorCode.INVALID_INPUT);
            }
        }
        return distinct.size();
    }

    private static String type(Item it) {
        return it.recordType() == null ? "" : it.recordType().toUpperCase();
    }
}
