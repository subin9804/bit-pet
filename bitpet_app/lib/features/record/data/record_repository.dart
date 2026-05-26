import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/record_models.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.watch(dioProvider));
});

class RecordRepository {
  final Dio _dio;
  RecordRepository(this._dio);

  // ── 체중 ──────────────────────────────────────────────────

  Future<List<WeightRecord>> getWeights(int petId) async {
    final res = await _dio.get('/pets/$petId/weights');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<WeightRecord> addWeight(
      int petId, double weightG, DateTime measuredAt, String? memo) async {
    final res = await _dio.post('/pets/$petId/weights', data: {
      'weightG': weightG,
      'measuredAt': measuredAt.toIso8601String(),
      if (memo != null) 'memo': memo,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => WeightRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '체중 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteWeight(int id) async {
    await _dio.delete('/weights/$id');
  }

  // ── 급여 ──────────────────────────────────────────────────

  Future<List<FeedingRecord>> getFeedings(int petId) async {
    final res = await _dio.get('/pets/$petId/feedings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => FeedingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<FeedingRecord> addFeeding(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/feedings', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => FeedingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '급여 기록 실패');
    }
    return apiRes.data!;
  }

  // ── 청소 ──────────────────────────────────────────────────

  Future<List<CleaningRecord>> getCleanings(int petId) async {
    final res = await _dio.get('/pets/$petId/cleanings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => CleaningRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<CleaningRecord> addCleaning(
      int petId, CleaningType type, DateTime cleanedAt, String? memo) async {
    final res = await _dio.post('/pets/$petId/cleanings', data: {
      'cleaningType': type.name,
      'cleanedAt': cleanedAt.toIso8601String(),
      if (memo != null) 'memo': memo,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => CleaningRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '청소 기록 실패');
    }
    return apiRes.data!;
  }

  // ── 메모 (v5) ─────────────────────────────────────────────

  Future<List<MemoTag>> getMemoTags() async {
    final res = await _dio.get('/memo-tags');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => MemoTag.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<List<Memo>> getMemos(int petId, {int page = 0, int size = 20}) async {
    final res = await _dio.get('/pets/$petId/memos',
        queryParameters: {'page': page, 'size': size});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) {
        final map = d as Map<String, dynamic>;
        return (map['items'] as List)
            .map((e) => Memo.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return apiRes.data ?? [];
  }

  Future<Memo> addMemo(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/memos', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Memo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '메모 저장 실패');
    }
    return apiRes.data!;
  }

  Future<Memo> updateMemo(int memoId, Map<String, dynamic> data) async {
    final res = await _dio.put('/memos/$memoId', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Memo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '메모 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteMemo(int memoId) async {
    await _dio.delete('/memos/$memoId');
  }

  // ── 교배 (v5) ─────────────────────────────────────────────

  Future<List<MatingRecord>> getMatings(int petId) async {
    final res = await _dio.get('/pets/$petId/matings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => MatingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<MatingRecord> addMating(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/matings', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => MatingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '교배 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteMating(int matingId) async {
    await _dio.delete('/matings/$matingId');
  }

  // ── 산란 (v5) ─────────────────────────────────────────────

  Future<List<LayingRecord>> getLayings(int petId) async {
    final res = await _dio.get('/pets/$petId/layings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => LayingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<LayingRecord> addLaying(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/layings', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => LayingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '산란 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteLaying(int layingId) async {
    await _dio.delete('/layings/$layingId');
  }

  // ── 달력 (v5) ─────────────────────────────────────────────

  Future<List<CalendarDay>> getCalendar(
      int petId, String yearMonth, List<String> categories) async {
    final res = await _dio.get('/pets/$petId/calendar', queryParameters: {
      'yearMonth': yearMonth,
      if (categories.isNotEmpty) 'categories': categories.join(','),
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  // ── 타임라인 (v5) ─────────────────────────────────────────

  Future<List<TimelineItem>> getTimeline(
    int petId, {
    String? from,
    String? to,
    List<String>? categories,
    int limit = 20,
  }) async {
    final res = await _dio.get('/pets/$petId/records', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (categories != null && categories.isNotEmpty)
        'categories': categories.join(','),
      'limit': limit,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => TimelineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  // ── 홈 최근 기록 ──────────────────────────────────────────

  Future<List<RecentRecord>> getRecentRecords({int limit = 5}) async {
    final res = await _dio.get('/records/recent',
        queryParameters: {'limit': limit});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => RecentRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }
}
