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
