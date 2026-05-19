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

  // 체중
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

  // 급여
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

  // 건강 메모
  Future<List<HealthMemo>> getHealthLogs(int petId) async {
    final res = await _dio.get('/pets/$petId/health-logs');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => HealthMemo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<HealthMemo> addHealthMemo(
      int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/health-logs', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => HealthMemo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '건강 메모 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteHealthMemo(int id) async {
    await _dio.delete('/health-logs/$id');
  }
}
