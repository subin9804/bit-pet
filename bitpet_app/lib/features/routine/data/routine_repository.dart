import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/routine_models.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(ref.watch(dioProvider));
});

class RoutineRepository {
  final Dio _dio;
  RoutineRepository(this._dio);

  Future<List<Routine>> getRoutines(int petId) async {
    final res = await _dio.get('/pets/$petId/schedules');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<Routine> createRoutine(CreateRoutineRequest request) async {
    final res = await _dio.post(
        '/pets/${request.petId}/schedules',
        data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Routine.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '루틴 등록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteRoutine(int id) async {
    await _dio.delete('/schedules/$id');
  }

  Future<void> completeRoutine(int id) async {
    await _dio.patch('/tasks/$id/complete');
  }
}
