import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../presentation/widgets/home_banner.dart';

/// 홈 상단 배너 (2026-11-24). 운영자가 웹 관리 페이지(tailog.me/admin/banners)에서 바꾼다.
///
/// 서버는 지금 노출 중인 것만 순서대로 준다 — 자녀 계정이면 외부 링크 배너도 이미 빠져 있다.
final homeBannerRepositoryProvider = Provider<HomeBannerRepository>((ref) {
  return HomeBannerRepository(dio: ref.watch(dioProvider));
});

/// 홈 배너 목록. **실패하면 빈 목록** — 배너는 홈의 곁가지라, 못 받았다고 오류를 띄우면
/// 홈 전체가 고장 난 것처럼 보인다. 비면 배너 자리째 사라진다.
final homeBannersProvider = FutureProvider<List<HomeBannerItem>>((ref) async {
  try {
    return await ref.watch(homeBannerRepositoryProvider).getBanners();
  } catch (_) {
    return const [];
  }
});

class HomeBannerRepository {
  final Dio _dio;

  HomeBannerRepository({required Dio dio}) : _dio = dio;

  Future<List<HomeBannerItem>> getBanners() async {
    final res = await _dio.get('/home/banners');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List).cast<Map<String, dynamic>>(),
    );
    if (!apiRes.success || apiRes.data == null) return const [];
    return apiRes.data!.map(_fromJson).toList();
  }

  /// 서버 `HomeBannerResponse` → 배너 한 장. linkType 이 ROUTE 면 앱 경로, URL 이면 외부 주소.
  static HomeBannerItem _fromJson(Map<String, dynamic> json) {
    final type = json['linkType'] as String?;
    final link = json['linkValue'] as String?;
    return HomeBannerItem(
      title: json['title'] as String,
      body: json['body'] as String?,
      badge: json['badge'] as String?,
      imageUrl: json['imageUrl'] as String?,
      route: type == 'ROUTE' ? link : null,
      url: type == 'URL' ? link : null,
    );
  }
}
