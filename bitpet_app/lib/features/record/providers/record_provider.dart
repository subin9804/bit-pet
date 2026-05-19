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

final healthMemoListProvider =
    FutureProvider.family<List<HealthMemo>, int>((ref, petId) {
  return ref.watch(recordRepositoryProvider).getHealthLogs(petId);
});
