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
    // 서버가 썸네일 자리까지 같이 서명해 내려준다(왕복을 늘리지 않고, 키 규칙을 서버가
    // 쥐고 있게 하려고). 구버전 서버면 없으므로 nullable 로 읽는다.
    final thumbPresignedUrl = presign['thumbPresignedUrl'] as String?;
    final thumbS3Key = presign['thumbS3Key'] as String?;

    // 2) S3 PUT — 원본
    await _uploader.putToPresignedUrl(presignedUrl, image.bytes, image.contentType);

    // 2-b) 축소본. 실패해도 업로드를 중단하지 않는다 — 썸네일이 없으면 서버가
    //      thumbnailUrl 을 비워 내리고 앱이 원본으로 폴백할 뿐이다.
    String? uploadedThumbKey;
    if (thumbPresignedUrl != null && thumbS3Key != null) {
      final thumb = await _uploader.makeThumbnail(image.bytes);
      if (thumb != null) {
        try {
          await _uploader.putToPresignedUrl(thumbPresignedUrl, thumb, 'image/jpeg');
          uploadedThumbKey = thumbS3Key;
        } catch (_) {
          // 원본은 이미 올라갔다. 여기서 던지면 사진이 통째로 실패한다.
        }
      }
    }

    // 3) register
    final regRes = await _dio.post('/photos', data: {
      'entityType': entityType,
      'entityId': entityId,
      's3Key': s3Key,
      'thumbS3Key': uploadedThumbKey,
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
