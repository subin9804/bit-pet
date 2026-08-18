import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/toast_message.dart';

/// 앱 밖으로 나가는 링크 모음. 여러 화면에서 같은 주소를 쓰므로 한 곳에 모은다.
class ExternalLinks {
  ExternalLinks._();

  /// NFC 이름표 주문처 (네이버 스마트스토어).
  static const smartStore = 'https://smartstore.naver.com/tailog_factory';

  /// 서비스 도메인.
  static const homepage = 'https://tailog.me';
}

/// 외부 링크 열기.
///
/// 실패를 조용히 삼키지 않는다 — 브라우저가 없거나 Android 11+ 의 `<queries>` 설정이
/// 빠지면 아무 반응 없이 버튼만 죽은 것처럼 보인다. 그럴 땐 토스트로 알린다.
Future<void> openExternalLink(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showToast(context, '링크를 열 수 없어요.', type: ToastType.error);
  }
}
