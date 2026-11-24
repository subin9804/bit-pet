// 산란(출산) 기록 ↔ 메이팅 기록 연결 칸.
//
// 서버는 처음부터 `laying_dtl.mating_id` 를 받았고, 알을 개체로 등록할 때 이 메이팅의
// 수컷을 **아비로 자동 연결**한다(`LayingService` 계보 생성). 앱에 고르는 칸이 없어서
// 지금까지 한 번도 채워진 적이 없었다 (2026-11-13 실기기 점검에서 발견).
//
// 산란 폼(FAB · 개체 상세)과 클러치 상세의 '메이팅' 시트가 이 칸 하나를 같이 쓴다.
//
// 2026-11-24: 칩 나열 → 메이팅 '파트너' 고르는 칸과 같은 테두리 목록(최대 높이 안에서 스크롤).
// 메이팅이 많으면 칩이 줄줄이 늘어 폼이 길어졌다 (사용자: "괜히 부피 늘어난다").
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/record_models.dart';
import '../../providers/record_provider.dart';

/// 이 암컷의 산란에 걸 수 있는 메이팅 — 최근순.
///
/// 서버 `validateMatingFemale` 과 같은 기준: 암컷 칸이 이 개체이거나 비어 있는 것.
List<MatingRecord> linkableMatings(List<MatingRecord> all, int petId) =>
    all.where((m) => m.femalePetId == null || m.femalePetId == petId).toList()
      ..sort((a, b) => b.triedAt.compareTo(a.triedAt));

/// 저장 시점에 보낼 matingId. [chosen] 이 false 면 연결 안 함.
///
/// 2026-11-25: 예전엔 산란일 이전 가장 최근 메이팅을 미리 골라 두고 그대로 걸었다.
/// 사용자가 모르는 사이에 아비가 정해지는 게 문제라 기본은 '연결 안 함'으로 바꿨다.
int? resolveMatingLink({required bool chosen, int? selectedId}) =>
    chosen ? selectedId : null;

/// 메이팅 한 건을 한 줄로 — `6/2 · 레오`. 올해가 아니면 연도를 붙인다.
String matingLinkLabel(MatingRecord m) {
  final d = m.triedAt.toLocal();
  final date = d.year == DateTime.now().year
      ? '${d.month}/${d.day}'
      : "'${d.year % 100}.${d.month}/${d.day}";
  final partner = m.malePetName ?? m.externalPartnerText ?? '상대 미입력';
  return '$date · $partner';
}

/// 고르는 칸. 라벨은 부르는 쪽 폼 규칙대로 위에 단다.
class MatingLinkPicker extends ConsumerWidget {
  final int petId;
  final DateTime laidAt;

  /// false 면 '연결 안 함'을 고른 것으로 보여 준다.
  final bool chosen;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const MatingLinkPicker({
    super.key,
    required this.petId,
    required this.laidAt,
    required this.chosen,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matingListProvider(petId));
    return async.when(
      loading: () => const SizedBox(
          height: 36,
          child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (_, _) =>
          Text('메이팅 기록을 불러오지 못했어요', style: AppTextStyles.caption),
      data: (all) {
        final list = linkableMatings(all, petId);
        final current = chosen ? selectedId : null;
        if (list.isEmpty) {
          return Text('이 개체의 메이팅 기록이 없어요', style: AppTextStyles.caption);
        }
        final picked = list.where((m) => m.id == current).firstOrNull;
        // 연결돼 있던 메이팅이 지워졌으면 목록에 없다 — '연결 안 함'이 아니라는 걸 알린다.
        final missing = current != null && picked == null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 파트너 고르는 칸(fab_record_sheet '파트너')과 같은 모양 — 최근순, 넘치면 안에서 스크롤
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: AppRadius.brMd,
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ClipRRect(
                borderRadius: AppRadius.brMd,
                child: ListView.separated(
                  // 시트(AppSheet)의 스크롤바가 PrimaryScrollController 를 쓴다 — 이 목록까지
                  // 붙으면 컨트롤러 하나에 위치가 둘이라 스크롤바가 assert 로 죽는다.
                  primary: false,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.line),
                  // '연결 안 함'이 맨 위 — 기본값이라 먼저 보이게.
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _Row(
                        title: '연결 안 함',
                        selected: current == null,
                        onTap: () => onChanged(null),
                      );
                    }
                    final m = list[i - 1];
                    return _Row(
                      title: m.malePetName ?? m.externalPartnerText ?? '상대 미입력',
                      sub: _sub(m),
                      selected: m.id == current,
                      onTap: () => onChanged(m.id),
                    );
                  },
                ),
              ),
            ),
            if (missing) ...[
              const SizedBox(height: 6),
              Text('연결된 메이팅 기록이 삭제됐어요',
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink3)),
            ],
          ],
        );
      },
    );
  }
}

/// 목록 둘째 줄 — `6월 2일 · 성공`. 올해가 아니면 연도를 붙인다.
String _sub(MatingRecord m) {
  final d = m.triedAt.toLocal();
  final date = d.year == DateTime.now().year
      ? '${d.month}월 ${d.day}일'
      : '${d.year}년 ${d.month}월 ${d.day}일';
  final result = switch (m.isSuccessful) {
    true => '성공',
    false => '실패',
    null => '결과 미정',
  };
  return '$date · $result';
}

class _Row extends StatelessWidget {
  final String title;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.brandTintSoft : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: sub == null ? FontWeight.w500 : FontWeight.w700,
                          color: sub == null ? AppColors.ink2 : AppColors.ink)),
                  if (sub != null)
                    Text(sub!,
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.brandAction, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
