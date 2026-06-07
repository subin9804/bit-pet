import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';

final weightListProvider =
    FutureProvider.family<List<WeightRecord>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getWeights(petId);
});

final feedingListProvider =
    FutureProvider.family<List<FeedingRecord>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getFeedings(petId);
});

final cleaningListProvider =
    FutureProvider.family<List<CleaningRecord>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getCleanings(petId);
});

// v5: health_memo → memo
final memoListProvider =
    FutureProvider.family<List<Memo>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getMemos(petId);
});

final memoTagsProvider = FutureProvider<List<MemoTag>>((ref) {
  return ref.watch(recordRepositoryProvider).getMemoTags();
});

final matingListProvider =
    FutureProvider.family<List<MatingRecord>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getMatings(petId);
});

final layingListProvider =
    FutureProvider.family<List<LayingRecord>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getLayings(petId);
});

final recentRecordsProvider = FutureProvider<List<RecentRecord>>((ref) {
  return ref.watch(recordRepositoryProvider).getRecentRecords();
});

// ── 홈 — 날짜별 전체 기록 ─────────────────────────────────────
final homeDayRecordsProvider =
    FutureProvider.family<List<RecentRecord>, String>((ref, date) {
  return ref.watch(recordRepositoryProvider).getRecordsByDate(date);
});

// ── 홈 — 전체 개체 달력 ───────────────────────────────────────
final homeCalendarProvider =
    FutureProvider.family<List<CalendarDay>, String>((ref, yearMonth) {
  return ref.watch(recordRepositoryProvider).getHomeCalendar(yearMonth);
});

// ── 개체 상세 — 달력 (월별 카테고리 점) ─────────────────────
class PetYearMonth {
  final int petId;
  final String yearMonth; // "YYYY-MM"
  const PetYearMonth(this.petId, this.yearMonth);
  @override bool operator ==(Object o) =>
      o is PetYearMonth && o.petId == petId && o.yearMonth == yearMonth;
  @override int get hashCode => Object.hash(petId, yearMonth);
}

final petCalendarProvider =
    FutureProvider.family<List<CalendarDay>, PetYearMonth>((ref, param) {
  return ref
      .watch(recordRepositoryProvider)
      .getCalendar(param.petId, param.yearMonth, const []);
});

// ── 개체 상세 — 선택일 타임라인 ──────────────────────────────
class PetDateParam {
  final int petId;
  final String date; // "YYYY-MM-DD"
  const PetDateParam(this.petId, this.date);
  @override bool operator ==(Object o) =>
      o is PetDateParam && o.petId == petId && o.date == date;
  @override int get hashCode => Object.hash(petId, date);
}

final petDayTimelineProvider =
    FutureProvider.family<List<TimelineItem>, PetDateParam>((ref, param) {
  return ref.watch(recordRepositoryProvider).getTimeline(
        param.petId,
        from: param.date,
        to:   param.date,
        limit: 50,
      );
});

// ── 개체 상세 — 요약 카드 (카테고리별 최신 1건) ─────────────
final petRecordSummaryProvider =
    FutureProvider.family<List<TimelineItem>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getTimeline(
        petId,
        limit: 30,
      );
});
