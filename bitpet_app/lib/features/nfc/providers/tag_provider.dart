import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tag_models.dart';
import '../data/tag_repository.dart';

/// 마이페이지 태그 관리 목록
final myTagsProvider = FutureProvider<List<MyTag>>((ref) {
  return ref.watch(tagRepositoryProvider).myTags();
});

/// 스캔한 태그의 조회 결과. TagResolverScreen이 이 값으로 분기한다.
final tagResolveProvider =
    FutureProvider.family<TagResolveResult, String>((ref, tagCd) {
  return ref.watch(tagRepositoryProvider).resolve(tagCd);
});

/// 로그인 전에 스캔한 태그 경로를 담아두는 자리.
///
/// 태그를 찍었는데 로그아웃 상태면 라우터가 /login으로 보내는데, 로그인 후 홈으로만
/// 떨어지면 첫 스캔이 그대로 증발한다. 여기에 담아두고 로그인 직후 되돌아간다.
///
/// 라우터 redirect 안에서 쓰이므로 Provider가 아니라 평범한 정적 변수로 둔다 —
/// redirect는 빌드 도중 호출되고, 그 안에서 Provider를 갱신하면 안 된다.
class PendingTagLink {
  PendingTagLink._();

  static String? _location;

  static void remember(String location) => _location = location;

  /// 한 번 꺼내면 비워진다.
  static String? take() {
    final loc = _location;
    _location = null;
    return loc;
  }
}
