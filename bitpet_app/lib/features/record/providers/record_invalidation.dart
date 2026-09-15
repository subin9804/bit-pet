// 기록 저장·수정·삭제 후 캐시 갱신을 한 곳에 모은다.
// 기록 provider 들은 autoDispose 가 아니라 한 번 불러오면 계속 남는다. 저장 경로마다
// 갱신 대상을 따로 적어두니 급여 상세에서 저장하면 캘린더 탭·요약 카드가 옛 값으로
// 남는 식의 누락이 생겼다 → 어떤 경로로 기록하든 이 함수 하나를 부른다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pet/providers/pet_provider.dart';
import 'feed_provider.dart';
import 'record_provider.dart';

/// [petId] 개체의 기록이 바뀌었을 때 호출.
///
/// [keepFeedSessions] — 급여 상세 화면처럼 [feedSessionsProvider] 상태를 직접 갱신한
/// 곳에서는 true. 다시 불러오면 목록이 잠깐 로딩 상태로 깜빡인다.
void invalidatePetRecords(WidgetRef ref, int petId,
    {bool keepFeedSessions = false}) {
  // 개체 상세 — 어느 달·어느 날짜에 기록됐는지 모르므로 family 전체를 비운다
  ref.invalidate(petCalendarProvider);
  ref.invalidate(petDayTimelineProvider);
  ref.invalidate(petRecordSummaryProvider(petId));
  ref.invalidate(petDetailProvider(petId));

  // 카테고리별 목록
  ref.invalidate(weightListProvider(petId));
  ref.invalidate(feedingListProvider(petId));
  ref.invalidate(cleaningListProvider(petId));
  ref.invalidate(memoListProvider(petId));
  ref.invalidate(matingListProvider(petId));
  ref.invalidate(layingListProvider(petId));
  if (!keepFeedSessions) ref.invalidate(feedSessionsProvider(petId));

  // 홈
  ref.invalidate(homeCalendarProvider);
  ref.invalidate(homeDayRecordsProvider);
  ref.invalidate(recentRecordsProvider);
}
