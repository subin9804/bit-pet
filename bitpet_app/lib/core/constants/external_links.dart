import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/toast_message.dart';

/// 앱 밖으로 나가는 링크 모음. 여러 화면에서 같은 주소를 쓰므로 한 곳에 모은다.
class ExternalLinks {
  ExternalLinks._();

  /// NFC 이름표 주문처 (네이버 스마트스토어).
  static const smartStore = 'https://smartstore.naver.com/tailog_factory';

  /// 서비스 도메인.
  static const homepage = 'https://tailog.me';

  /// 고객 문의. Cloudflare Email Routing 으로 운영 계정에 전달된다.
  static const supportEmail = 'help@tailog.me';

  /// 개인정보 관련 문의. 처리방침에 명시되는 주소라 문의용과 분리한다 —
  /// 공개 문서에 적힌 주소는 스팸 수집 대상이 되고, 그게 곧 문의함이면 진짜 문의가 묻힌다.
  static const privacyEmail = 'privacy@tailog.me';
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

/// 메일 앱 열기.
///
/// 메일 앱이 하나도 없는 기기가 꽤 있다. 그때 아무 일도 안 일어나면 버튼이 고장난
/// 것처럼 보이므로, 주소를 클립보드에 넣어 주고 그 사실을 알린다.
Future<void> openMailTo(
  BuildContext context,
  String address, {
  String? subject,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: address,
    query: subject == null
        ? null
        : 'subject=${Uri.encodeComponent(subject)}',
  );

  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // 처리할 수 있는 앱이 없으면 플랫폼이 예외를 던진다 — 아래 폴백으로 넘긴다
  }
  if (opened || !context.mounted) return;

  await Clipboard.setData(ClipboardData(text: address));
  if (context.mounted) {
    showToast(context, '메일 주소를 복사했어요 · $address');
  }
}
