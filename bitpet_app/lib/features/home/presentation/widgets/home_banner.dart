// 홈 상단 배너 — 공지·이벤트·홍보물이 들어갈 자리.
//
// ⚠️ **지금은 임시다.** 내용은 아래 [kHomeBanners] 에 하드코딩돼 있고 서버 연동이 없다.
// 연동할 때 바꿀 곳은 그 상수 하나이고, 위젯은 `List<HomeBannerItem>` 만 받으므로
// provider 로 갈아끼우면 끝이다 (`HomeBanner(items: ref.watch(...))`).
//
// 설계상 지킬 것 두 가지:
//   • **비면 자리도 사라진다** — 배너가 없는 날 빈 박스가 남으면 레이아웃이 고장 난 것처럼
//     보인다. `items` 가 비면 `SizedBox.shrink()` 다.
//   • **높이는 화면의 1/7~1/8** (`_kHeightDivisor` + clamp). 홈의 주인공은 '오늘 할 일'
//     히어로이고 배너가 그걸 밀어내면 안 된다. 큰 화면에서 비례로 커지다 못해
//     히어로를 가리는 걸 막기 위해 상한을 둔다.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 배너 한 장. 서버 연동 시 이 모양 그대로 DTO 에서 만들면 된다.
class HomeBannerItem {
  final String title;

  /// 제목 아래 한 줄. 두 줄 이상 쓰지 말 것 — 높이가 1/8 화면이라 넘친다.
  final String? body;

  /// 왼쪽 작은 꼬리표 ('이벤트', '공지'…). 없으면 안 그린다.
  final String? badge;

  /// 탭했을 때 갈 앱 내부 경로. null 이면 **탭이 아예 안 먹는다**(눌리는 것처럼
  /// 보이면서 아무 일도 안 일어나는 게 제일 나쁘다).
  final String? route;

  /// 채울 이미지. 연동 전에는 null → 글자만 있는 틴트 카드로 그린다.
  final String? imageUrl;

  const HomeBannerItem({
    required this.title,
    this.body,
    this.badge,
    this.route,
    this.imageUrl,
  });
}

/// 연동 전 임시 내용. ⛔ 여기에 실제 홍보 문구를 쌓지 말 것 — 스토어 심사를 기다려야 한다.
const kHomeBanners = <HomeBannerItem>[
  HomeBannerItem(
    badge: '공지',
    title: '배너 자리입니다',
    body: '이벤트·공지·홍보물이 여기 들어갑니다',
  ),
];

const double _kHeightDivisor = 7.5; // 1/7 ~ 1/8 사이
const double _kMinHeight = 96;
const double _kMaxHeight = 132;

class HomeBanner extends StatefulWidget {
  final List<HomeBannerItem> items;

  /// 탭 처리는 바깥에 맡긴다 — 라우팅을 이 위젯이 알면 테스트가 어려워진다.
  final void Function(HomeBannerItem item)? onTap;

  const HomeBanner({super.key, this.items = kHomeBanners, this.onTap});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final height = (MediaQuery.sizeOf(context).height / _kHeightDivisor)
        .clamp(_kMinHeight, _kMaxHeight);

    return Column(
      children: [
        SizedBox(
          height: height,
          // 한 장이면 PageView 를 쓰지 않는다 — 넘길 게 없는데 스크롤이 먹으면
          // 세로 스크롤과 싸운다.
          child: items.length == 1
              ? _Card(item: items.first, onTap: widget.onTap)
              : PageView.builder(
                  controller: _controller,
                  itemCount: items.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) =>
                      _Card(item: items[i], onTap: widget.onTap),
                ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (i) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.brandAction : AppColors.line,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final HomeBannerItem item;
  final void Function(HomeBannerItem item)? onTap;
  const _Card({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tappable = item.route != null && onTap != null;

    return GestureDetector(
      onTap: tappable ? () => onTap!(item) : null,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // 흰 카드로 두면 아래 히어로와 같은 무게로 읽혀 어느 쪽이 주인공인지
          // 흐려진다. 브랜드 틴트로 깔아 "서비스가 하는 말"로 구분한다.
          color: AppColors.brandTintSoft,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.brandTint),
        ),
        child: item.imageUrl != null
            // 이미지 배너는 글자를 얹지 않는다 — 어떤 그림이 올지 모르는데
            // 위에 텍스트를 깔면 대비가 깨져 둘 다 안 읽힌다.
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _text(),
              )
            : _text(),
      ),
    );
  }

  Widget _text() => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(item.badge!,
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.brandTintInk)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(item.title,
                      style: AppTextStyles.subheading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (item.body != null) ...[
                    const SizedBox(height: 2),
                    Text(item.body!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (item.route != null)
              const Icon(Icons.chevron_right,
                  size: AppIconSize.md, color: AppColors.brandIcon),
          ],
        ),
      );
}
