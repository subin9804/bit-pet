import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/photo_models.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(dioProvider));
});

class PhotoRepository {
  final Dio _dio;
  PhotoRepository(this._dio);

  Future<List<PetPhoto>> getPhotos({
    required String entityType, // PET / MEMO / MATING / LAYING
    required int entityId,
  }) async {
    final res = await _dio.get('/photos', queryParameters: {
      'entityType': entityType,
      'entityId': entityId,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => PetPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<PetPhoto> uploadPhoto({
    required String entityType,
    required int entityId,
    required String uploadUrl, // presigned PUT URL
    required String key,
  }) async {
    final res = await _dio.post('/photos', data: {
      'entityType': entityType,
      'entityId': entityId,
      'key': key,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => PetPhoto.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '사진 등록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deletePhoto(int photoId) async {
    await _dio.delete('/photos/$photoId');
  }
}
