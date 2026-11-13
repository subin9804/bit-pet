// 산란(출산) 기록 ↔ 메이팅 기록 연결 칸.
//
// 서버는 처음부터 `laying_dtl.mating_id` 를 받았고, 알을 개체로 등록할 때 이 메이팅의
// 수컷을 **아비로 자동 연결**한다(`LayingService` 계보 생성). 앱에 고르는 칸이 없어서
// 지금까지 한 번도 채워진 적이 없었다 (2026-11-13 실기기 점검에서 발견).
//
// 산란 폼(FAB · 개체 상세)과 클러치 상세의 '메이팅' 시트가 이 칸 하나를 같이 쓴다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../data/models/record_models.dart';
import '../../providers/record_provider.dart';

/// 화면에 늘어놓는 최근 메이팅 수. 그보다 오래된 건 지금 고른 것만 덧붙인다.
const _kVisible = 5;

/// 이 암컷의 산란에 걸 수 있는 메이팅 — 최근순.
///
/// 서버 `validateMatingFemale` 과 같은 기준: 암컷 칸이 이 개체이거나 비어 있는 것.
List<MatingRecord> linkableMatings(List<MatingRecord> all, int petId) =>
    all.where((m) => m.femalePetId == null || m.femalePetId == petId).toList()
      ..sort((a, b) => b.triedAt.compareTo(a.triedAt));

/// 아무것도 고르지 않았을 때 미리 골라 둘 메이팅.
///
/// 산란일 **이전**의 가장 최근 것. 뒤에 한 메이팅은 이 알의 부모일 수 없고,
/// '실패'로 적은 메이팅도 건너뛴다 (고르면 그대로 걸 수는 있다).
int? defaultMatingId(List<MatingRecord> all, int petId, DateTime laidAt) {
  final cutoff = DateTime(laidAt.year, laidAt.month, laidAt.day + 1);
  for (final m in linkableMatings(all, petId)) {
    if (m.isSuccessful == false) continue;
    if (m.triedAt.toLocal().isBefore(cutoff)) return m.id;
  }
  return null;
}

/// 저장 시점에 보낼 matingId. [chosen] 이 false 면 기본값(최근)을 따른다.
Future<int?> resolveMatingLink(
  WidgetRef ref, {
  required int petId,
  required DateTime laidAt,
  required bool chosen,
  int? selectedId,
}) async {
  if (chosen) return selectedId;
  try {
    final all = await ref.read(matingListProvider(petId).future);
    return defaultMatingId(all, petId, laidAt);
  } catch (_) {
    return null; // 못 불러오면 연결 없이 저장한다 — 산란 기록 자체를 막지 않는다
  }
}

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

  /// false 면 [defaultMatingId] 를 고른 것으로 보여 준다.
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
        final current =
            chosen ? selectedId : defaultMatingId(all, petId, laidAt);
        if (list.isEmpty) {
          return Text('이 개체의 메이팅 기록이 없어요', style: AppTextStyles.caption);
        }
        final shown = list.take(_kVisible).toList();
        final picked = list.where((m) => m.id == current).firstOrNull;
        if (picked != null && !shown.contains(picked)) shown.add(picked);
        // 연결돼 있던 메이팅이 지워졌으면 칩이 없다 — '연결 안 함'이 아니라는 걸 알린다.
        final missing = current != null && picked == null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in shown)
                  AppChip(
                    label: matingLinkLabel(m),
                    selected: m.id == current,
                    onTap: () => onChanged(m.id),
                  ),
                AppChip(
                  label: '연결 안 함',
                  selected: current == null,
                  onTap: () => onChanged(null),
                ),
              ],
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
