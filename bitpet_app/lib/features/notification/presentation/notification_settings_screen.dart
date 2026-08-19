import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/notification_provider.dart';

/// 알림 설정 — 종류별 수신 토글.
///
/// 여기서 끄는 것은 <b>푸시</b>다. 끈 알림도 앱 내 알림함에는 그대로 쌓인다.
/// 사용자가 원하는 건 폰이 안 울리는 것이지 무슨 일이 있었는지 모르는 게 아니다.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// OS 알림 권한. null 이면 아직 확인 전.
  ///
  /// 이걸 보여주지 않으면 앱 안에서 토글을 다 켜놓고도 알림이 안 와서
  /// 앱이 고장난 줄 알게 된다. 실제 원인은 OS 권한인데 앱 화면에는 단서가 없다.
  bool? _osAllowed;

  @override
  void initState() {
    super.initState();
    _checkOsPermission();
  }

  Future<void> _checkOsPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _osAllowed =
            settings.authorizationStatus != AuthorizationStatus.denied &&
                settings.authorizationStatus != AuthorizationStatus.notDetermined;
      });
    } catch (_) {
      // Firebase 미초기화(iOS 등)면 배너를 감춘다. 확인 못 한 것을
      // '권한 없음'으로 보여주면 멀쩡한 상태에 경고를 띄우게 된다.
      if (mounted) setState(() => _osAllowed = true);
    }
  }

  Future<void> _requestOsPermission() async {
    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {
      // 무시 — 아래 재확인 결과로 판단한다
    }
    await _checkOsPermission();
    if (!mounted) return;
    if (_osAllowed != true) {
      // 한 번 거부한 뒤에는 OS 가 다이얼로그를 다시 띄우지 않는다.
      showToast(context, '휴대폰 설정 > 앱 > tailog > 알림 에서 켜주세요',
          type: ToastType.warning);
    }
  }

  Future<void> _toggle(Future<String?> Function() action) async {
    final error = await action();
    if (error != null && mounted) {
      showToast(context, error, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefState = ref.watch(notificationPrefProvider);
    final notifier = ref.read(notificationPrefProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('알림 설정', style: AppTextStyles.title),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: prefState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: '알림 설정을 불러오지 못했어요',
          onRetry: notifier.load,
        ),
        data: (pref) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (_osAllowed == false) _OsPermissionBanner(onTap: _requestOsPermission),

            const _SectionLabel('사육 기록'),
            _ToggleRow(
              icon: Icons.alarm,
              label: '루틴 알림',
              description: '급여·체중·청소 예정 알림',
              value: pref.routine,
              onChanged: (v) => _toggle(() => notifier.setRoutine(v)),
            ),

            const _SectionLabel('커뮤니티'),
            _ToggleRow(
              icon: Icons.mode_comment_outlined,
              label: '댓글 알림',
              description: '내 글에 달린 댓글',
              value: pref.comment,
              onChanged: (v) => _toggle(() => notifier.setComment(v)),
            ),
            _ToggleRow(
              icon: Icons.favorite_border,
              label: '좋아요 알림',
              description: '내 글을 좋아한 사람',
              value: pref.postLike,
              onChanged: (v) => _toggle(() => notifier.setPostLike(v)),
            ),

            const _SectionLabel('기타'),
            // 끌 수 없는 항목이지만 목록에서 빼지 않는다. 없으면 "공지도 껐는데 왜 오지"가
            // 되고, 있으면 끌 수 없다는 사실이 그 자리에서 설명된다.
            const _FixedOnRow(
              icon: Icons.campaign_outlined,
              label: '공지사항',
              description: '점검·업데이트 안내 · 끌 수 없어요',
            ),
            _ToggleRow(
              icon: Icons.local_offer_outlined,
              label: '마케팅·이벤트',
              description: '신기능·굿즈 소식',
              value: pref.marketing,
              onChanged: (v) => _toggle(() => notifier.setMarketing(v)),
            ),

            const _MarketingNotice(),
            const _PushOnlyNotice(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.body),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.toggleOn,
                inactiveTrackColor: AppColors.toggleOff,
              ),
            ],
          ),
        ),
      );
}

/// 끌 수 없는 항목. 스위치를 비활성 상태로 두는 대신 텍스트로 대체한다 —
/// 회색 스위치는 "지금 꺼져 있음"으로 읽히기 쉬운데 사실은 정반대다.
class _FixedOnRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _FixedOnRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(description, style: AppTextStyles.caption),
                ],
              ),
            ),
            Text('항상 켜짐',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textDisabled)),
          ],
        ),
      );
}

class _OsPermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _OsPermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.notifications_off_outlined,
                    size: 20, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('휴대폰 알림이 꺼져 있어요',
                          style: AppTextStyles.bodyBold),
                      const SizedBox(height: 2),
                      Text('아래 설정과 상관없이 알림이 오지 않아요. 눌러서 켜주세요.',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MarketingNotice extends StatelessWidget {
  const _MarketingNotice();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Text(
          '마케팅·이벤트 수신 동의는 변경 시각이 기록으로 남아요. '
          '동의하지 않아도 서비스 이용에는 제한이 없어요.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
        ),
      );
}

class _PushOnlyNotice extends StatelessWidget {
  const _PushOnlyNotice();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Text(
          '끈 알림도 알림함에는 그대로 쌓여요. 휴대폰이 울리지 않을 뿐이에요.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
        ),
      );
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
}
