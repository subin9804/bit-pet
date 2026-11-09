import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../mock/mock_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_buttons.dart';

/// 강제 업데이트 (2026-11-09). 서버 `GET /app/version` 의 minVersion 보다 낮으면 앱을 막는다.
///
/// 스플래시에서 기다리지 않는다(스플래시 주석 참고) — 앱은 평소대로 뜨고, 판정이 끝나서
/// 막아야 하면 그때 [ForceUpdateGate] 가 화면 전체를 덮는다.
/// 네트워크 실패·서버 구버전 등 **판정이 안 되면 막지 않는다** — 오프라인 사용자를 가두면 안 된다.
final forceUpdateProvider = FutureProvider<String?>((ref) async {
  if (kMockMode) return null;
  try {
    final info = await PackageInfo.fromPlatform();
    final res = await ref
        .read(dioProvider)
        .get<Map<String, dynamic>>(
          '/app/version',
          queryParameters: {'platform': Platform.isIOS ? 'ios' : 'android'},
        );
    final data = res.data?['data'] as Map<String, dynamic>?;
    final min = data?['minVersion'] as String?;
    if (min == null || !isVersionBelow(info.version, min)) return null;
    final storeUrl = data?['storeUrl'] as String?;
    return storeUrl ?? '';
  } catch (e) {
    debugPrint('[ForceUpdate] 판정 실패 — 막지 않음: $e');
    return null;
  }
});

/// `1.2.3` 형식 비교. 숫자가 아닌 꼬리(`-beta`, `+4`)는 버린다.
bool isVersionBelow(String current, String min) {
  List<int> parse(String v) => v
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final a = parse(current), b = parse(min);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}

/// `MaterialApp.builder` 에 끼운다. 업데이트가 필요하면 라우터 화면 대신 안내만 보여준다.
class ForceUpdateGate extends ConsumerWidget {
  final Widget child;
  const ForceUpdateGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeUrl = ref.watch(forceUpdateProvider).valueOrNull;
    if (storeUrl == null) return child;
    return _UpdateRequiredScreen(storeUrl: storeUrl);
  }
}

class _UpdateRequiredScreen extends StatelessWidget {
  final String storeUrl;
  const _UpdateRequiredScreen({required this.storeUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/branding/login_main.png', width: 140),
              const SizedBox(height: 24),
              Text('새 버전으로 업데이트해 주세요', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                '지금 버전은 더 이상 지원하지 않아요.\n업데이트하면 기록은 그대로 이어져요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              if (storeUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: AppActionButton(
                    '업데이트하러 가기',
                    onPressed: () => launchUrl(
                      Uri.parse(storeUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
