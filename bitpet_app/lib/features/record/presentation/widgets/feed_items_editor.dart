import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/food_catalog.dart';
import 'feed_item_modal.dart';
import '../../../../core/theme/app_dimens.dart';

export '../../data/food_catalog.dart' show FeedFormData, FoodType, FeedingSupplement;

/// 다중 급여 아이템 편집기 — 루틴 완료 모달 내 공유 위젯
/// items: 이미 추가된 목록 / onChanged: 목록 변경 콜백
///
/// **여기엔 기록 전체에 관한 것만 둔다.** 먹였나/거부했나, 그리고 담긴 목록.
/// 종류·양·마릿수·영양제는 항목 하나에 속한 값이라 [showFeedItemModal] 로 나가 있다.
/// 예전엔 둘이 한 줄로 쌓여 있어서, 먹이 하나를 적으려는 사람에게 칸이 여덟 개로 보였다.
///
/// ℹ️ 메모는 이 위젯이 그리지 않는다 — 호출하는 화면이 각자 자기 자리에 둔다.
class FeedItemsEditor extends StatefulWidget {
  final List<FeedFormData> items;
  final ValueChanged<List<FeedFormData>> onChanged;
  final Color bandColor;

  const FeedItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.bandColor = AppColors.feedBand,
  });

  @override
  State<FeedItemsEditor> createState() => _FeedItemsEditorState();
}

class _FeedItemsEditorState extends State<FeedItemsEditor> {
  /// 거식은 단독 기록 — 목록에 이 항목이 있으면 다른 먹이를 함께 담을 수 없다
  bool get _hasRefused => widget.items.any((i) => i.isRefused);

  /// 모달에서 담아온 것만 목록에 들어간다.
  ///
  /// 예전엔 입력 중인 한 건을 `_current` 로 들고 있다가 `추가하기` 를 눌러야 목록에
  /// 넣었는데, 저장할 땐 목록만 봤다 — 다 채우고 추가를 안 누른 채 저장하면 입력이
  /// **조용히 버려졌다.** 담는 순간이 곧 모달을 닫는 순간이라 그 틈이 사라졌다.
  Future<void> _add() async {
    final item = await showFeedItemModal(context, bandColor: widget.bandColor);
    if (item == null) return;
    widget.onChanged([...widget.items, item]);
  }

  /// 담긴 항목을 눌러 고친다 — 같은 모달을 값과 함께 연다.
  Future<void> _edit(int i) async {
    final item = await showFeedItemModal(
      context,
      bandColor: widget.bandColor,
      initial: widget.items[i],
    );
    if (item == null) return;
    final list = [...widget.items]..[i] = item;
    widget.onChanged(list);
  }

  /// 거식 전환. 거식은 단독 기록이라 켜면 앞서 담아둔 먹이는 의미가 없어지므로
  /// 목록을 통째로 갈아끼운다.
  void _setRefused(bool refused) {
    if (refused == _hasRefused) return;
    widget.onChanged(refused ? const [FeedFormData(isRefused: true)] : const []);
  }

  void _remove(int i) {
    final list = [...widget.items];
    list.removeAt(i);
    widget.onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 먹였어요 / 거부했어요 ────────────────────────────
        // 예전엔 '거식' 체크박스였다. 켜는 순간 아래 네 필드가 통째로 사라지는
        // **모드 전환**인데 생김새는 영양제 옆의 선택 항목 같았다 — 하는 일과
        // 보이는 모양이 어긋나 있었다. 기록의 종류가 갈리는 자리이므로 승격시킨다.
        _RefusedSegment(
          refused: _hasRefused,
          bandColor: widget.bandColor,
          onChanged: _setRefused,
        ),

        // 거식이면 목록도 추가 버튼도 없다. 남는 건 메모뿐이고 그건 바깥이 그린다.
        if (!_hasRefused) ...[
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('급여 내용'),
          const SizedBox(height: AppSpacing.sm),
          ...widget.items.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ItemRow(
              item: e.value,
              bandColor: widget.bandColor,
              onTap: () => _edit(e.key),
              onRemove: () => _remove(e.key),
            ),
          )),
          _AddButton(onTap: _add),
        ],
      ],
    );
  }
}

// ── 먹였어요 / 거부했어요 ──────────────────────────────────────────────────────
class _RefusedSegment extends StatelessWidget {
  final bool refused;
  final Color bandColor;
  final ValueChanged<bool> onChanged;
  const _RefusedSegment({
    required this.refused,
    required this.bandColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    // 트랙은 `paleBgAlt` 다. `paleBg` 는 `card` 와 같은 값이라, 그걸 깔면
    // 선택된 칸(card)이 트랙에 묻혀 어느 쪽이 켜진 건지 안 보인다.
    decoration: BoxDecoration(
      color: AppColors.paleBgAlt,
      border: Border.all(color: AppColors.paleLine),
      borderRadius: AppRadius.brLg,
    ),
    child: Row(children: [
      Expanded(child: _seg('먹였어요', !refused, () => onChanged(false))),
      Expanded(child: _seg('거부했어요', refused, () => onChanged(true))),
    ]),
  );

  Widget _seg(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(vertical: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? (refused ? bandColor : AppColors.card) : Colors.transparent,
        borderRadius: AppRadius.brMd,
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13,
        fontWeight: on ? FontWeight.w700 : FontWeight.w600,
        color: on ? AppColors.primary : AppColors.paleInk3,
      )),
    ),
  );
}

// ── 급여 추가 ──────────────────────────────────────────────────────────────────
/// 담긴 항목(테두리 있는 카드)과 **같은 것으로 읽히면 안 된다** — 이건 담긴 내용이 아니라
/// 담는 자리다. 그래서 테두리 없이 바닥을 한 톤 눌러 홈처럼 보이게 둔다.
/// (`paleBg` 는 `card` 와 같은 값이라 여기선 쓸 수 없다 — 차이가 안 난다.)
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.paleBgAlt,
        borderRadius: AppRadius.brLg,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 16, color: AppColors.paleInk2),
          SizedBox(width: AppSpacing.sm),
          Text('급여 추가',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.paleInk2,
            )),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11.5, fontWeight: FontWeight.w700,
      color: AppColors.paleInk2, letterSpacing: 0.3,
    ),
  );
}

class _ItemRow extends StatelessWidget {
  final FeedFormData item;
  final Color bandColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ItemRow({
    required this.item,
    required this.bandColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final label = item.summary.isNotEmpty ? item.summary : (item.foodType?.label ?? '');
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: AppRadius.brLg,
        ),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: bandColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.close, size: 16, color: AppColors.paleInk3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
