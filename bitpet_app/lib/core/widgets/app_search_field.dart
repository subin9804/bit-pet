import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 공용 검색 입력칸 — **흰 카드 + 돋보기 + 지우기**.
/// 목록 위에 얹는 검색창은 앱 전체가 이 위젯만 쓴다.
///
/// ⚠️ 전에는 같은 검색창을 화면마다 손으로 그렸고, 그래서 **모양이 셋이었다**:
/// 내 개체는 둥근 카드(16), 루틴 Step2 는 각진 박스(12) + 회색 테두리,
/// FAB 대상 선택은 알약(999). 같은 일을 하는 칸이 화면마다 다른 모양이면
/// 사용자는 그걸 다른 기능으로 읽는다. 기준은 [AppDecor.card] 하나다.
///
/// ⚠️ 테마 기본 입력칸은 **밑줄**이다. 연회색 바탕에 밑줄만 그으면 옛 테마로
/// 보이므로, 바탕 위의 흰 카드로 띄워 다른 섹션과 같은 층에 둔다.
class AppSearchField extends StatefulWidget {
  /// 바깥이 들고 있는 현재 검색어. 이 값이 바뀌면 칸의 글자도 따라간다 —
  /// 바깥에서 `''` 로 되돌리면 칸도 비워진다.
  ///
  /// ⚠️ 예전 FAB 검색창은 컨트롤러 없는 `TextField` 였다. 'X' 를 눌러도
  /// state 의 검색어만 비고 **칸에는 글자가 남아** 목록과 어긋났다.
  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;

  /// 글자가 있을 때 오른쪽에 'X' 를 띄운다. 목록이 길어 스크롤을 내린
  /// 자리에서는 지우기 한 번이 키보드 여는 것보다 빠르다.
  final bool clearable;

  /// 처음 그려질 때 키보드를 연다. 버튼으로 펼치는 검색창(커뮤니티 목록)은
  /// 펼친 뒤 칸을 한 번 더 누르게 하지 않는다.
  final bool autofocus;

  const AppSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = '이름 또는 종 검색',
    this.clearable = true,
    this.autofocus = false,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(AppSearchField old) {
    super.didUpdateWidget(old);
    // 바깥 값이 기준이다. 사용자가 타이핑해서 올라간 값은 이미 같으므로
    // 커서가 튀지 않고, 바깥에서 비운 경우에만 칸이 따라 비워진다.
    if (widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.search,
              size: AppIconSize.md, color: AppColors.ink3),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _c,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText,
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.ink3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md),
              ),
            ),
          ),
          if (widget.clearable && widget.value.isNotEmpty)
            GestureDetector(
              onTap: () => widget.onChanged(''),
              behavior: HitTestBehavior.opaque,
              // 작은 아이콘은 손가락이 빗나간다 — 보이는 크기는 sm 이지만
              // 눌리는 면은 좌우 여백까지 포함해 넓혀 둔다.
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(Icons.close,
                    size: AppIconSize.sm, color: AppColors.ink3),
              ),
            ),
        ],
      ),
    );
  }
}
