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

  // ---------------------------------------------------------------------------
  // Routine CRUD
  // ---------------------------------------------------------------------------

  Future<List<Routine>> getRoutines() async {
    final res = await _dio.get('/routines');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<Routine> getRoutine(int routineId) async {
    final res = await _dio.get('/routines/$routineId');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Routine.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: 404, message: '루틴을 찾을 수 없습니다');
    }
    return apiRes.data!;
  }

  Future<Routine> createRoutine(CreateRoutineRequest request) async {
    final res = await _dio.post('/routines', data: request.toJson());
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

  Future<Routine> updateRoutine(int routineId, Map<String, dynamic> body) async {
    final res = await _dio.put('/routines/$routineId', data: body);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Routine.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: '루틴 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteRoutine(int routineId) async {
    await _dio.delete('/routines/$routineId');
  }

  // ---------------------------------------------------------------------------
  // Pet subscription
  // ---------------------------------------------------------------------------

  Future<void> subscribePet(int routineId, int petId) async {
    await _dio.post('/routines/$routineId/pets/$petId');
  }

  Future<void> unsubscribePet(int routineId, int petId) async {
    await _dio.delete('/routines/$routineId/pets/$petId');
  }

  Future<List<int>> getSubscribedPetIds(int routineId) async {
    final res = await _dio.get('/routines/$routineId/pets');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List).map((e) => e as int).toList(),
    );
    return apiRes.data ?? [];
  }

  // ---------------------------------------------------------------------------
  // Pet-view: routines with subscription status
  // ---------------------------------------------------------------------------

  Future<List<RoutineWithSubscription>> getRoutinesForPet(int petId) async {
    final res = await _dio.get('/pets/$petId/routines');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => RoutineWithSubscription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  // ---------------------------------------------------------------------------
  // Routine completion
  // ---------------------------------------------------------------------------

  Future<List<RoutineLog>> completeBatch(
      int routineId, RoutineCompleteBatchRequest request) async {
    final res = await _dio.post(
      '/routines/$routineId/complete/batch',
      data: request.toJson(),
    );
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => RoutineLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<RoutineLog?> completeIndividual(
      int routineId, RoutineCompleteIndividualRequest request) async {
    final res = await _dio.post(
      '/routines/$routineId/complete/individual',
      data: request.toJson(),
    );
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d != null ? RoutineLog.fromJson(d as Map<String, dynamic>) : null,
    );
    return apiRes.data;
  }

  // ---------------------------------------------------------------------------
  // Routine logs
  // ---------------------------------------------------------------------------

  Future<List<RoutineLog>> getLogs(int routineId) async {
    final res = await _dio.get('/routines/$routineId/logs');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => RoutineLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<void> deleteLog(int logId) async {
    await _dio.delete('/routine-logs/$logId');
  }
}
