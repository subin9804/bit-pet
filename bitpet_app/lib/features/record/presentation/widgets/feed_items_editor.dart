import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../data/food_catalog.dart';
import '../../data/feed_recent_repository.dart';
import 'feed_item_modal.dart';
import '../../../../core/theme/app_dimens.dart';

export '../../data/food_catalog.dart' show FeedFormData, FoodType, FeedingSupplement;

/// 다중 급여 아이템 편집기 — 루틴 완료 모달 내 공유 위젯
/// items: 이미 추가된 목록 / onChanged: 목록 변경 콜백
///
/// **여기엔 기록 전체에 관한 것만 둔다.** 급여냐 거식이냐, 그리고 담긴 목록.
/// 종류·양·마릿수·영양제는 항목 하나에 속한 값이라 [showFeedItemModal] 로 나가 있다.
/// 예전엔 둘이 한 줄로 쌓여 있어서, 먹이 하나를 적으려는 사람에게 칸이 여덟 개로 보였다.
///
/// ℹ️ 메모는 이 위젯이 그리지 않는다 — 호출하는 화면이 각자 자기 자리에 둔다.
class FeedItemsEditor extends ConsumerStatefulWidget {
  final List<FeedFormData> items;
  final ValueChanged<List<FeedFormData>> onChanged;
  final Color bandColor;

  /// 최근 조합 칩을 띄울 개체. **여러 개체를 한꺼번에 기록하는 자리에서는 null** —
  /// 최근 급여는 개체마다 다르고, 다섯 마리에게 공통인 "최근"은 존재하지 않는다.
  /// 아무 개체의 기록이나 대표로 보여주면 옆 개체 걸 그대로 담게 된다.
  final int? petId;

  const FeedItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.bandColor = AppColors.feedBand,
    this.petId,
  });

  @override
  ConsumerState<FeedItemsEditor> createState() => _FeedItemsEditorState();
}

class _FeedItemsEditorState extends ConsumerState<FeedItemsEditor> {
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
    _remember(item);
  }

  /// 담긴 조합을 다음번 최근 칩으로 남긴다. 기록 저장이 아니라 **담는 순간**에
  /// 남기는 이유는, 저장은 이 위젯 밖에서 일어나고 취소될 수도 있기 때문이다.
  /// 취소된 조합이 칩에 남는 건 손해가 아니다 — 고르려던 게 맞긴 했다.
  void _remember(FeedFormData item) {
    final petId = widget.petId;
    if (petId == null) return;
    ref.read(feedRecentRepositoryProvider).remember(petId, item).then((_) {
      if (mounted) ref.invalidate(recentFeedsProvider(petId));
    });
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
        // ── 급여 / 거식 ──────────────────────────────────────
        // 예전엔 '거식' 체크박스였다. 켜는 순간 아래 네 필드가 통째로 사라지는
        // **모드 전환**인데 생김새는 영양제 옆의 선택 항목 같았다 — 하는 일과
        // 보이는 모양이 어긋나 있었다. 기록의 종류가 갈리는 자리이므로 승격시킨다.
        //
        // 라벨은 '먹였어요/거부했어요' 가 아니라 명사 한 쌍이다. 기록을 보여주는
        // 쪽은 이미 전부 '거식' 으로 쓰고 있어서(food_catalog·feed_models·
        // record_screen·feed_detail_screen) 입력에서만 다르게 부를 이유가 없다.
        _RefusedSegment(
          refused: _hasRefused,
          bandColor: widget.bandColor,
          onChanged: _setRefused,
        ),

        // 거식이면 목록도 추가 버튼도 없다. 남는 건 메모뿐이고 그건 바깥이 그린다.
        if (!_hasRefused) ...[
          // ── 최근 급여 ────────────────────────────────────
          // 같은 걸 또 주는 날엔 여기서 끝난다 (탭 2회). 모달까지 가는 경로는
          // 새 조합을 만들 때만 쓴다.
          //
          // 한때 이 줄을 '급여 내용' 섹션 안, 목록과 추가 버튼 사이에 넣어봤다.
          // 논리적으로는 맞았지만(칩도 버튼도 목록을 채우는 도구다) **읽히지
          // 않았다** — 칩과 `_ItemRow` 가 배경·테두리·모서리까지 거의 같은
          // 모양이라, 목록 바로 밑에 붙자 이미 담긴 항목으로 보였다.
          // 그래서 셋으로 갈라둔다: 자리가 다르고(목록 위), 제목이 있고,
          // 칩마다 `＋` 가 붙는다.
          if (widget.petId != null)
            _RecentChips(
              petId: widget.petId!,
              bandColor: widget.bandColor,
              onPick: (f) {
                widget.onChanged([...widget.items, f]);
                _remember(f);
              },
            ),

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

// ── 최근 조합 ─────────────────────────────────────────────────────────────────
/// 누르면 **바로 담긴다.** 고르는 게 아니라 하는 것이라 선택 상태가 없다
/// (그래서 `AppChip` 은 항상 `selected: false` 로 쓴다).
///
/// 기록이 없는 개체·처음 쓰는 기기에서는 **섹션째** 그리지 않는다. 빈 자리에
/// '최근 급여 없음' 같은 문구를 두면 아무것도 할 수 없는 줄만 남는다.
class _RecentChips extends ConsumerWidget {
  final int petId;
  final Color bandColor;
  final ValueChanged<FeedFormData> onPick;

  const _RecentChips({
    required this.petId,
    required this.bandColor,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFeedsProvider(petId));

    // 로딩·에러도 빈 화면이다. 로컬 SQLite 한 방이라 로딩이 눈에 띌 일이 없고,
    // 실패해도 잃는 건 단축키뿐이라 `＋ 급여 추가` 로 다 할 수 있다.
    final list = recent.valueOrNull ?? const <FeedFormData>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        // '최근' 이 아니라 '빠른 추가' 다. 이름이 **동사**여야 누르는 것임이 읽힌다
        // ('최근 기록' 은 홈 피드와도 겹쳐서 어느 최근인지 헷갈렸다).
        const _SectionLabel('빠른 추가'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: list
              .map((f) => AppChip(
                    // `＋` 를 라벨에 직접 붙인다. `AppChip` 에 아이콘 슬롯이 없기도 하지만,
                    // 아래 `＋ 급여 추가` 버튼과 **같은 기호를 공유하는 것 자체가 설명**이다 —
                    // ＋ 가 붙은 건 누르면 목록에 담기는 것, 안 붙은 건 이미 담긴 것.
                    label: '＋ ${f.summary}',
                    selected: false,
                    onTap: () => onPick(f),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── 급여 / 거식 ───────────────────────────────────────────────────────────────
class _RefusedSegment extends StatelessWidget {
  final bool refused;
  final Color bandColor;
  final ValueChanged<bool> onChanged;
  const _RefusedSegment({
    required this.refused,
    required this.bandColor,
    required this.onChanged,
  });

  // 두 칸이 **하나의 곡선**을 공유해야 한다. 예전엔 칸마다 `AnimatedContainer` 를
  // 두고 배경색만 페이드시켰는데, 그러면 ① 왼쪽이 흐려지는 동안 오른쪽이 진해지는
  // 크로스페이드라 움직임이 뭉개지고 ② 글자의 굵기·색은 `Text.style` 이라
  // 애니메이션 밖에서 **즉시 튄다** — 배경은 느리고 글자는 빠른 그 시차가 어색함의
  // 정체였다. 이제 썸 하나가 미끄러지고, 글자도 같은 duration/curve 를 탄다.
  static const _dur = Duration(milliseconds: 190);
  static const _curve = Curves.easeOutCubic;

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
    child: Stack(
      children: [
        // 썸. `Positioned.fill` 이라 크기는 아래 `Row` 가 정한다 — 글자 높이가
        // 바뀌어도 따로 맞출 값이 없다.
        Positioned.fill(
          child: AnimatedAlign(
            duration: _dur,
            curve: _curve,
            alignment: refused ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: _dur,
                curve: _curve,
                decoration: BoxDecoration(
                  color: refused ? bandColor : AppColors.card,
                  borderRadius: AppRadius.brMd,
                ),
              ),
            ),
          ),
        ),
        Row(children: [
          Expanded(child: _seg('급여', !refused, () => onChanged(false))),
          Expanded(child: _seg('거식', refused, () => onChanged(true))),
        ]),
      ],
    ),
  );

  Widget _seg(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedDefaultTextStyle(
      duration: _dur,
      curve: _curve,
      style: TextStyle(
        fontSize: 13,
        fontWeight: on ? FontWeight.w700 : FontWeight.w600,
        color: on ? AppColors.primary : AppColors.paleInk3,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Text(label, textAlign: TextAlign.center),
      ),
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
