import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/food_catalog.dart';
import 'feed_composer_fields.dart';

export '../../data/food_catalog.dart' show FeedFormData, FoodType, FeedingSupplement;

/// 다중 급여 아이템 편집기 — 루틴 완료 모달 내 공유 위젯
/// items: 이미 추가된 목록 / onChanged: 목록 변경 콜백
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
  FeedFormData _current = const FeedFormData();

  void _add() {
    if (_current.foodType == null) return;
    widget.onChanged([...widget.items, _current]);
    setState(() => _current = const FeedFormData());
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
        // ── 컴포저 ──────────────────────────────────────────
        FeedComposerFields(
          form: _current,
          bandColor: widget.bandColor,
          showMemo: false,
          onChanged: (f) => setState(() => _current = f),
          onAdd: _add,
        ),
        // ── 추가된 아이템 목록 ─────────────────────────────
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(color: AppColors.paleLine, height: 1),
          const SizedBox(height: 10),
          _SectionLabel('추가된 급여'),
          const SizedBox(height: 8),
          ...widget.items.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ItemRow(
              item: e.value,
              bandColor: widget.bandColor,
              onRemove: () => _remove(e.key),
            ),
          )),
        ],
      ],
    );
  }
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
  final VoidCallback onRemove;

  const _ItemRow({
    required this.item,
    required this.bandColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final label = item.summary.isNotEmpty ? item.summary : (item.foodType?.label ?? '');
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: bandColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
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
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 14, color: AppColors.paleInk3),
            ),
          ),
        ],
      ),
    );
  }
}
