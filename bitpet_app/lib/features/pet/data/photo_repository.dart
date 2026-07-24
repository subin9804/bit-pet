import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/upload/image_upload.dart';
import 'models/photo_models.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(
    ref.watch(dioProvider),
    ref.watch(imageUploadServiceProvider),
  );
});

class PhotoRepository {
  final Dio _dio;
  final ImageUploadService _uploader;
  PhotoRepository(this._dio, this._uploader);

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

  /// 갤러리에서 고른 이미지를 presign → S3 PUT → 등록까지 처리.
  Future<PetPhoto> upload({
    required String entityType,
    required int entityId,
    required PickedImage image,
  }) async {
    // 1) presign
    final presignRes = await _dio.post('/photos/presign', data: {
      'entityType': entityType,
      'entityId': entityId,
      'fileName': image.filename,
      'contentType': image.contentType,
    });
    final presign = ApiResponse.fromJson(
      presignRes.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    ).data!;
    final presignedUrl = presign['presignedUrl'] as String;
    final s3Key = presign['s3Key'] as String;

    // 2) S3 PUT
    await _uploader.putToPresignedUrl(presignedUrl, image.bytes, image.contentType);

    // 3) register
    final regRes = await _dio.post('/photos', data: {
      'entityType': entityType,
      'entityId': entityId,
      's3Key': s3Key,
      'fileSize': image.bytes.length,
      'mimeType': image.contentType,
    });
    final apiRes = ApiResponse.fromJson(
      regRes.data as Map<String, dynamic>,
      (d) => PetPhoto.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: regRes.statusCode ?? 0,
          message: apiRes.message ?? '사진 등록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deletePhoto(int photoId) async {
    await _dio.delete('/photos/$photoId');
  }
}
