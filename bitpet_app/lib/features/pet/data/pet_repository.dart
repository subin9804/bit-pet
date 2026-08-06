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

  Future<Pet?> findBySerial(String serialNo) async {
    try {
      final res = await _dio.get('/pets/by-serial',
          queryParameters: {'serialNo': serialNo.toUpperCase()});
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => Pet.fromJson(d as Map<String, dynamic>),
      );
      return apiRes.success ? apiRes.data : null;
    } catch (_) {
      return null;
    }
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

  /// 이별하기 — 폐사 처리 (기록은 그대로 보존)
  Future<Pet> markDeceased(int id) async {
    final res = await _dio.post('/pets/$id/deceased');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Pet.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '이별 처리에 실패했습니다.');
    }
    return apiRes.data!;
  }

  /// 이별 취소 — 폐사 표시 해제
  Future<Pet> revertDeceased(int id) async {
    final res = await _dio.delete('/pets/$id/deceased');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Pet.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '이별 취소에 실패했습니다.');
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

  /// 개체 일괄 삭제. 서버에서 **전부 성공 아니면 전부 실패**로 처리한다
  /// (소유자가 아닌 개체가 하나라도 섞이면 아무것도 지워지지 않고 403).
  /// 실제로 지워진 id 목록을 돌려준다 — 요청에 중복이 있었다면 더 짧을 수 있다.
  Future<List<int>> deletePets(List<int> ids) async {
    final res = await _dio.delete('/pets', data: {'petIds': ids});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => ((d as Map<String, dynamic>)['deletedIds'] as List)
          .cast<int>(),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '개체 삭제에 실패했습니다.');
    }
    return apiRes.data!;
  }

  /// 갤러리 사진 하나를 대표(프로필) 사진으로 지정
  Future<Pet> setProfilePhoto(int petId, int photoId) async {
    final res = await _dio.put('/pets/$petId/profile-photo/$photoId');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Pet.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '대표 사진 설정 실패');
    }
    return apiRes.data!;
  }

  // subcategory(G/L/C/S/T/F/N) 또는 category(R/A) 필터 가능, 둘 다 null이면 전체
  Future<List<Species>> getSpecies({String? subcategory, String? category}) async {
    final params = <String, String>{};
    if (subcategory != null) params['subcategory'] = subcategory;
    if (category != null && subcategory == null) params['category'] = category;
    final res = await _dio.get('/species', queryParameters: params.isEmpty ? null : params);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => Species.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<void> addRelation(int childPetId, int parentPetId, String relationType) async {
    await _dio.post('/pets/relations', data: {
      'parentPetId': parentPetId,
      'childPetId': childPetId,
      'relationType': relationType,
    });
  }

  Future<void> deleteRelation(int relationId) async {
    await _dio.delete('/pets/relations/$relationId');
  }

  // 종별 모프 목록 — GET /species/{speciesId}/morphs
  Future<List<Morph>> getMorphs(int speciesId) async {
    final res = await _dio.get('/species/$speciesId/morphs');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => Morph.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }
}
