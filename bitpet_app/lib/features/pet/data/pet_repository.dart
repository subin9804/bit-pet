import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/pet_models.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.watch(dioProvider));
});

class PetRepository {
  final Dio _dio;
  PetRepository(this._dio);

  Future<List<Pet>> getMyPets() async {
    final res = await _dio.get('/pets');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List).map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList(),
    );
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '개체 목록을 불러오지 못했습니다.');
    }
    return apiRes.data ?? [];
  }

  Future<Pet> getPet(int id) async {
    final res = await _dio.get('/pets/$id');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Pet.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '개체 정보를 불러오지 못했습니다.');
    }
    return apiRes.data!;
  }

  Future<Pet> createPet(CreatePetRequest request) async {
    final res = await _dio.post('/pets', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Pet.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '개체 등록에 실패했습니다.');
    }
    return apiRes.data!;
  }

  Future<Pet> updatePet(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/pets/$id', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Pet.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '개체 수정에 실패했습니다.');
    }
    return apiRes.data!;
  }

  Future<void> deletePet(int id) async {
    final res = await _dio.delete('/pets/$id');
    final apiRes = ApiResponse<void>.fromJson(
        res.data as Map<String, dynamic>, null);
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '개체 삭제에 실패했습니다.');
    }
  }

  Future<List<Species>> getSpecies() async {
    final res = await _dio.get('/species');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => Species.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }
}
