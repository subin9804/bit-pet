import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/toast_message.dart';
import '../providers/share_provider.dart';

/// 공유 허브 — 공유코드·받은 초대·시작 안내를 한 곳에 모은 진입 화면.
/// 마이페이지 '공유 관리'에서 진입.
class ShareHubScreen extends ConsumerWidget {
  const ShareHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedCount = ref.watch(receivedBatchesProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('공유 관리')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(receivedBatchesProvider);
          ref.invalidate(myShareCodeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 시작 안내 + CTA
            _StartCard(),
            const SizedBox(height: 20),

            // 내 공유코드
            Text('내 공유코드', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('상대방이 이 코드로 나를 공유·입분양 대상으로 지정해요.',
                style: AppTextStyles.caption),
            const SizedBox(height: 10),
            const _ShareCodeCard(),
            const SizedBox(height: 24),

            // 받은 초대
            _InboxRow(count: receivedCount),
          ],
        ),
      ),
    );
  }
}

/// 개체 공유·분양 시작 안내 카드 → 개체 관리 탭으로 이동
class _StartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('개체 공유·분양 시작하기', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '내 개체 관리에서 개체를 선택한 뒤 "함께 키우기" 또는 "분양 보내기"를 누르면, 여러 마리를 한 번에 보낼 수 있어요.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/pets'),
              icon: const Icon(Icons.pets, size: 18),
              label: const Text('내 개체 관리로 이동'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 받은 초대 요약 행 → 초대함으로 이동
class _InboxRow extends StatelessWidget {
  final int count;
  const _InboxRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/share/inbox'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.paleLine),
        ),
        child: Row(
          children: [
            const Icon(Icons.mail_outline,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text('받은 공유 초대', style: AppTextStyles.body)),
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count',
                    style: AppTextStyles.label.copyWith(color: Colors.white)),
              ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

/// 내 공유코드 카드 — 조회 시 서버가 없으면 발급. 복사 지원.
class _ShareCodeCard extends ConsumerWidget {
  const _ShareCodeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(myShareCodeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Row(
        children: [
          codeAsync.when(
            loading: () => Text('발급 중...', style: AppTextStyles.h2),
            error: (_, __) => Text('불러오기 실패', style: AppTextStyles.caption),
            data: (code) => Text(
              code,
              style: AppTextStyles.h2.copyWith(
                letterSpacing: 3.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Spacer(),
          codeAsync.maybeWhen(
            data: (code) => IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: AppColors.textSecondary,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ToastMessage.show(context, '공유코드를 복사했어요');
                }
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
