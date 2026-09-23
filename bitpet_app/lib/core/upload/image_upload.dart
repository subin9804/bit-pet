import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 썸네일 축소 기준 — 짧은 변이 이 값 아래로는 내려가지 않게 비율을 유지해 줄인다.
/// 512면 화면 폭(≈400dp)을 채우는 개체 상세 상단까지 견딘다. 원본이 필요한 자리는
/// 확대 뷰어뿐이고, 거기는 `url`(원본)을 그대로 쓴다.
const int kThumbMaxEdge = 512;

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
/// - 갤러리에서 이미지 선택 (1장 / 여러 장)
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

  /// 갤러리에서 여러 장 선택. 취소하면 빈 목록.
  ///
  /// [limit] 은 "앞으로 몇 장 더 받을 수 있는가"(= 최대치 − 이미 고른 수)다. 남은 칸을
  /// 넘겨주면 갤러리가 그 수만큼만 고르게 막아준다 — 다 고르고 나서 "5장까지예요" 라고
  /// 돌려보내는 것보다 낫다. 그래도 플랫폼이 무시할 수 있으니 호출부에서 한 번 더 자른다.
  ///
  /// `limit: 1` 도 안전하다 — image_picker 가 알아서 단일 선택기로 넘긴다.
  Future<List<PickedImage>> pickMultiFromGallery({int? limit}) async {
    final xs = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2000,
      limit: limit,
    );
    final out = <PickedImage>[];
    for (final x in xs) {
      final bytes = await x.readAsBytes();
      out.add(PickedImage(
        bytes: bytes,
        filename: x.name,
        contentType: contentTypeFor(x.name),
      ));
    }
    return out;
  }

  /// 짧은 변 [kThumbMaxEdge]px 기준 JPEG 썸네일을 만든다. 실패하면 null — 호출부는 썸네일 없이
  /// 원본만 올리고, 서버·앱 모두 `thumbnailUrl ?? url` 로 폴백하므로 사진 등록은 그대로 된다.
  ///
  /// 썸네일이 필요한 이유는 디코딩 비용이다. 34px 아바타와 목록 그리드가 3MB 원본을 받아
  /// 매번 풀사이즈로 디코딩하던 게 스크롤이 버벅이던 원인이었다.
  ///
  /// 포맷을 JPEG 로 고정한 건 플랫폼 차이 때문이다 — WebP 인코딩은 Android 에서만 되고,
  /// 원본 포맷을 따라가면 HEIC 썸네일 같은 게 섞인다. 서버의 키 규칙(`_thumb.jpg`)과도 맞물린다.
  Future<Uint8List?> makeThumbnail(Uint8List bytes) async {
    try {
      final out = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: kThumbMaxEdge,
        minHeight: kThumbMaxEdge,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      // minWidth/minHeight 는 '이 크기 아래로는 줄이지 않는다'는 뜻이라, 원본이 이미
      // 작으면 축소가 거의 없다. 그 경우 굳이 두 번 올릴 필요가 없다.
      return out.length < bytes.length ? out : null;
    } catch (e) {
      debugPrint('썸네일 생성 실패 — 원본만 업로드한다: $e');
      return null;
    }
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
