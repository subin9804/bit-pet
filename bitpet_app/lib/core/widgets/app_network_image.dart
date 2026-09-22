import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 네트워크 사진을 그리는 **단일 지점**. ⛔ `Image.network` 를 직접 쓰지 말 것.
///
/// 서버는 사진 URL 을 S3 presigned GET 으로 내려주는데, 서명 유효기간이 15분
/// (`BITPET_S3_PRESIGN_TTL`)이라 **같은 사진이라도 조회할 때마다 URL 이 달라진다**
/// (`X-Amz-Date`·`X-Amz-Signature` 쿼리). 플러터의 이미지 캐시는 URL 전체를 키로
/// 쓰기 때문에, 그냥 두면 탭을 나갔다 들어오기만 해도 매번 캐시 미스가 나 사진을
/// 처음부터 다시 받았다. 사진이 늦게 뜬 주된 이유가 이것이다.
///
/// 그래서 캐시 키를 **서명을 뺀 경로**(`cacheKeyOf`)로 고정한다. URL 이 바뀌어도
/// 같은 사진으로 인식해 디스크 캐시가 먹고, 앱을 재실행해도 살아남는다.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// 디코딩 목표 폭(px). 목록·아바타처럼 작게 그리는 자리에 넘기면 원본
  /// 해상도 그대로 메모리에 올리지 않는다 — 34px 칩에 3MB 짜리 원본을
  /// 펼쳐두던 게 스크롤이 버벅이던 이유다.
  final int? memWidth;

  /// 사진이 없거나 실패했을 때 그릴 것. 없으면 옅은 회색 면.
  final Widget? placeholder;

  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memWidth,
    this.placeholder,
  });

  /// 쿼리스트링(= presign 서명)을 떼어낸 안정적인 캐시 키.
  ///
  /// origin 까지 포함해 남긴다 — 경로만 쓰면 버킷이 다른 같은 이름의 키가
  /// 서로를 덮어쓴다. 파싱에 실패하면 URL 을 그대로 키로 쓴다(캐시가 덜 먹을 뿐
  /// 틀린 사진이 뜨지는 않는다).
  static String cacheKeyOf(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    return '${u.origin}${u.path}';
  }

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ??
        Container(width: width, height: height, color: AppColors.bgAlt);

    final u = url;
    if (u == null || u.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: u,
      cacheKey: cacheKeyOf(u),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memWidth,
      // 사진이 뜨기 전에는 자리만 지킨다. 스피너를 돌리면 목록 스크롤에서
      // 칸마다 뱅글이가 돌아 화면이 시끄러워진다.
      placeholder: (_, __) =>
          Container(width: width, height: height, color: AppColors.bgAlt),
      errorWidget: (_, __, ___) => fallback,
      fadeInDuration: const Duration(milliseconds: 160),
    );
  }
}
