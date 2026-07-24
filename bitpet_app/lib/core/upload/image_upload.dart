import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 선택한 이미지의 원본 바이트 + 파일명 + content-type 묶음.
class PickedImage {
  final Uint8List bytes;
  final String filename;
  final String contentType;
  const PickedImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });
}

/// 이미지 업로드 공용 헬퍼.
/// - 갤러리에서 이미지 1장 선택
/// - presigned PUT URL로 S3(LocalStack)에 직접 업로드
///
/// presign/register(등록)는 각 도메인 repository가 담당하고,
/// 여기서는 "선택"과 "S3 PUT"만 공용으로 제공한다.
class ImageUploadService {
  // presigned URL은 절대 URL(S3/LocalStack)이라 앱 API dio(baseUrl·인증 인터셉터)를
  // 쓰면 안 된다. 인터셉터 없는 순수 Dio로 PUT 한다.
  final Dio _rawDio = Dio();
  final ImagePicker _picker = ImagePicker();

  /// 갤러리에서 이미지 1장 선택. 취소 시 null.
  Future<PickedImage?> pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final name = x.name;
    return PickedImage(
      bytes: bytes,
      filename: name,
      contentType: contentTypeFor(name),
    );
  }

  /// presigned PUT URL로 바이트 업로드. content-type은 presign 시점과 반드시 일치해야 함.
  Future<void> putToPresignedUrl(
      String presignedUrl, Uint8List bytes, String contentType) async {
    await _rawDio.put(
      presignedUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }

  /// 파일명 확장자로 content-type 추론 (백엔드 resolveContentType과 일치해야 함).
  static String contentTypeFor(String filename) {
    final dot = filename.lastIndexOf('.');
    final ext = dot >= 0 ? filename.substring(dot + 1).toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}

final imageUploadServiceProvider =
    Provider<ImageUploadService>((ref) => ImageUploadService());
